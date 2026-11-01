use anyrender::{PaintScene as _, render_to_buffer};
use anyrender_vello_cpu::VelloCpuImageRenderer;
use blitz_dom::{DocumentConfig, NodeId, util::Color};
use blitz_html::HtmlDocument;
use blitz_net::Provider;
use blitz_paint::paint_scene;
use blitz_traits::shell::{ColorScheme, Viewport};
use peniko::Fill;
use peniko::kurbo::Rect;
use reqwest::Url;
use std::path::{Path, PathBuf};
use std::sync::Arc;
use std::{fs::File, io::Write};

// Usage: conformance_render <input_path_or_url> <output_path> [width] [height] [scale]
//
// If the output path ends in `.json`, the layout tree is dumped instead of a
// PNG: one record per element and text run, with absolute geometry and text.
// That is what the content and geometry comparison of tools/render-diff reads,
// because WebVeld cardinal rule 1 is equivalence of content, not identity of
// pixels (spec section 3.1).
#[tokio::main]
async fn main() {
    let args: Vec<String> = std::env::args().collect();
    if args.len() < 3 {
        eprintln!("Usage: {} <input_html_or_url> <output_png> [width=800] [height=600] [scale=1.0]", args[0]);
        std::process::exit(1);
    }

    let input = &args[1];
    let output_path = PathBuf::from(&args[2]);
    let width: u32 = args.get(3).and_then(|s| s.parse().ok()).unwrap_or(800);
    let height: u32 = args.get(4).and_then(|s| s.parse().ok()).unwrap_or(600);
    let scale: f64 = args.get(5).and_then(|s| s.parse().ok()).unwrap_or(1.0);

    let (url, html) = if input.starts_with("http://") || input.starts_with("https://") || input.starts_with("file://") {
        let url = Url::parse(input).expect("Failed to parse URL");
        let html = match url.scheme() {
            "file" => {
                let bytes = std::fs::read(url.path()).expect("Failed to read file");
                String::from_utf8(bytes).expect("HTML is not valid UTF-8")
            }
            _ => {
                let client = reqwest::Client::new();
                let resp = client.get(url.clone()).send().await.expect("Failed to fetch URL");
                resp.text().await.expect("Failed to decode response body")
            }
        };
        (url, html)
    } else {
        let path = Path::new(input);
        let abs_path = std::fs::canonicalize(path).unwrap_or_else(|_| path.to_path_buf());
        let html = std::fs::read_to_string(&abs_path).expect("Failed to read input file");
        let url = Url::from_file_path(&abs_path).expect("Failed to construct file URL");
        (url, html)
    };

    let url_string = url.to_string();
    let net = Arc::new(Provider::new(None));

    let mut document = HtmlDocument::from_html(
        &html,
        DocumentConfig {
            base_url: Some(url_string),
            net_provider: Some(Arc::clone(&net) as _),
            viewport: Some(Viewport::new(
                (width as f64 * scale) as u32,
                (height as f64 * scale) as u32,
                scale as f32,
                ColorScheme::Light,
            )),
            ..Default::default()
        },
    );

    loop {
        document.resolve(0.0);
        if net.is_empty() {
            break;
        }
    }

    document.as_mut().resolve(0.0);

    let render_width = (width as f64 * scale) as u32;
    let render_height = if height == 0 {
        let computed = document.as_ref().root_element().final_layout().size.height;
        ((computed as f64).max(600.0).min(10000.0) * scale) as u32
    } else {
        (height as f64 * scale) as u32
    };

    if output_path.extension().map(|e| e == "json").unwrap_or(false) {
        // The reader-visible text of the whole document, in order. This is the
        // content bar of spec section 3.1; the per-node records below are for
        // geometry and are not a reliable text source, because inline elements
        // do not get their own layout boxes.
        let mut collected = String::new();
        visible_text(document.as_ref(), document.as_ref().root_node().id, &mut collected);
        let body_text = collected.split_whitespace().collect::<Vec<_>>().join(" ");
        let mut out = format!("{{\n  \"text\": \"{}\",\n  \"boxes\": [\n", esc(&body_text));
        let mut first = true;
        dump_node(document.as_ref(), document.as_ref().root_node().id, 0.0, 0.0, &mut out, &mut first);
        out.push_str("\n  ]\n}\n");
        if let Some(parent) = output_path.parent() { std::fs::create_dir_all(parent).ok(); }
        std::fs::write(&output_path, out).expect("Failed to write layout JSON");
        println!("Dumped layout to {}", output_path.display());
        return;
    }

    let buffer = render_to_buffer::<VelloCpuImageRenderer, _>(
        |scene| {
            scene.fill(
                Fill::NonZero,
                Default::default(),
                Color::WHITE,
                Default::default(),
                &Rect::new(0.0, 0.0, render_width as f64, render_height as f64),
            );

            paint_scene(
                scene,
                document.as_mut(),
                scale,
                render_width,
                render_height,
                0,
                0,
            );
        },
        render_width,
        render_height,
    );

    if let Some(parent) = output_path.parent() {
        std::fs::create_dir_all(parent).ok();
    }

    let mut file = File::create(&output_path).expect("Failed to create output file");
    write_png(&mut file, &buffer, render_width, render_height);
    println!("Rendered {}x{} to {}", render_width, render_height, output_path.display());
}

/// Reader-visible text in document order. `text_content()` is not usable here:
/// it descends into `head`, so `title` and `style` bodies end up in the output,
/// and it concatenates adjacent runs with no separator so "A" + "Col" becomes
/// "ACol". This skips the non-rendered subtrees and separates every run.
fn visible_text(doc: &blitz_dom::BaseDocument, id: NodeId, out: &mut String) {
    let Some(node) = doc.get_node(id) else { return };
    if let blitz_dom::node::NodeData::Element(e) = &node.data {
        match e.name.local.as_ref() {
            // `select` is excluded on both sides: a closed select shows one
            // option and an open one shows a popup neither engine puts in the
            // page, so whose text counts as visible is engine-defined.
            "head" | "script" | "style" | "title" | "meta" | "link" | "noscript" | "select" => {
                return;
            }
            _ => {}
        }
        // Text the reader cannot see is not content. Without this the walk
        // reports `display: none` subtrees — a closed `details` body, say — as
        // text Chromium "dropped", which is the harness misreading itself.
        // Compared by its rendered form rather than by importing the type:
        // `stylo` is not a dependency of Blitz's examples package, and adding
        // one would make these instructions require editing Blitz itself.
        if let Some(styles) = node.primary_styles() {
            // Stylo's Display is a packed bitfield whose Debug form is
            // `Display(<bits>)`; zero is `display: none`. Compared this way
            // because `stylo` is not a dependency of Blitz's examples package
            // and adding one would make these instructions require editing
            // Blitz itself. Set DUMP_DISPLAY=1 to see the values if this
            // representation ever changes.
            // Inline elements legitimately have no layout box of their own, so the
        // laid-out test applies only to the rest.
        if !is_inline(e.name.local.as_ref()) {
            out.push(' ');
        }
        let d = format!("{:?}", styles.clone_display());
            if std::env::var("DUMP_DISPLAY").is_ok() {
                eprintln!("display[{}] = {}", e.name.local, d);
            }
            if d == "Display(0)" {
                return;
            }
        }
    }
    if let blitz_dom::node::NodeData::Text(t) = &node.data {
        out.push_str(&t.content);
    }
    for &child in node.children.iter() {
        visible_text(doc, child, out);
    }
}

/// Section 4.3's text-level elements. Text runs either side of one of these
/// belong to the same line and must not be separated, or `H<sub>2</sub>O`
/// becomes "H 2 O"; a run either side of anything else is a separate block and
/// must be. This is what `innerText` does, expressed against the specification's
/// own element list rather than against computed display, which is not reachable
/// from here without making `stylo` a dependency of Blitz's examples package.
fn is_inline(name: &str) -> bool {
    matches!(name,
        "a" | "strong" | "em" | "i" | "b" | "u" | "code" | "kbd" | "samp" | "var" | "abbr"
        | "cite" | "q" | "mark" | "small" | "sub" | "sup" | "del" | "ins" | "dfn" | "time"
        | "br" | "wbr" | "span")
}

fn esc(s: &str) -> String {
    let mut o = String::with_capacity(s.len());
    for c in s.chars() {
        match c {
            '"' => o.push_str("\\\""),
            '\\' => o.push_str("\\\\"),
            '\n' | '\r' | '\t' => o.push(' '),
            c if (c as u32) < 0x20 => o.push(' '),
            c => o.push(c),
        }
    }
    o
}

/// Walks the layout tree accumulating absolute positions, emitting one record
/// per element and per non-empty text run. Taffy stores each box's location
/// relative to its parent, so the absolute position is the running sum.
fn dump_node(
    doc: &blitz_dom::BaseDocument,
    id: NodeId,
    ox: f32,
    oy: f32,
    out: &mut String,
    first: &mut bool,
) {
    let Some(node) = doc.get_node(id) else { return };
    let layout = node.final_layout();
    let x = ox + layout.location.x;
    let y = oy + layout.location.y;

    // Text lives in Parley's inline layout rather than in boxed layout nodes, so
    // an element's own text is gathered from its immediate DOM text children.
    let (kind, name, text) = match &node.data {
        blitz_dom::node::NodeData::Element(e) => {
            let mut t = String::new();
            for &c in node.children.iter() {
                if let Some(cn) = doc.get_node(c) {
                    if let blitz_dom::node::NodeData::Text(td) = &cn.data {
                        if !t.is_empty() { t.push(' ') }
                        t.push_str(td.content.trim());
                    }
                }
            }
            ("element", e.name.local.to_string(), t.split_whitespace().collect::<Vec<_>>().join(" "))
        }
        _ => ("other", String::new(), String::new()),
    };

    if kind == "element" {
        if !*first { out.push_str(",\n") }
        *first = false;
        out.push_str(&format!(
            "  {{\"kind\":\"{}\",\"name\":\"{}\",\"x\":{:.1},\"y\":{:.1},\"w\":{:.1},\"h\":{:.1},\"text\":\"{}\"}}",
            kind, esc(&name), x, y, layout.size.width, layout.size.height, esc(&text)
        ));
    }

    let children: Vec<NodeId> = node
        .layout_children
        .borrow()
        .as_ref()
        .map(|c| c.iter().copied().collect())
        .unwrap_or_else(|| node.children.iter().copied().collect());
    for child in children {
        dump_node(doc, child, x, y, out, first);
    }
}

fn write_png<W: Write>(writer: W, buffer: &[u8], width: u32, height: u32) {
    const PPM: u32 = (144.0 * 39.3701) as u32;
    let mut encoder = png::Encoder::new(writer, width, height);
    encoder.set_color(png::ColorType::Rgba);
    encoder.set_depth(png::BitDepth::Eight);
    encoder.set_pixel_dims(Some(png::PixelDimensions {
        xppu: PPM,
        yppu: PPM,
        unit: png::Unit::Meter,
    }));
    let mut writer = encoder.write_header().unwrap();
    writer.write_image_data(buffer).unwrap();
    writer.finish().unwrap();
}
