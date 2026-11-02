use pdf_inspector::{
    process_pdf_mem_with_options, MarkdownOptions, MarkdownProfile, PdfOptions, PdfType,
    ProcessMode,
};
use rustler::{Atom, Binary, NifMap, NifStruct, NifUnitEnum};

mod atoms {
    rustler::atoms! { text_based, scanned, image_based, mixed }
}

#[derive(NifUnitEnum)]
enum Mode {
    Full,
    Detect,
    Analyze,
}

#[derive(NifUnitEnum)]
enum Profile {
    Fidelity,
    Compact,
}

#[derive(NifMap)]
struct Options {
    mode: Mode,
    pages: Option<Vec<u32>>,
    password: Option<String>,
    profile: Profile,
    page_breaks: bool,
}

#[derive(NifStruct)]
#[module = "PdfInspector.Result"]
struct Extraction {
    markdown: Option<String>,
    pdf_type: Atom,
    page_count: u32,
    processing_time_ms: u64,
    confidence: f32,
    pages_needing_ocr: Vec<u32>,
    has_encoding_issues: bool,
    title: Option<String>,
    author: Option<String>,
    subject: Option<String>,
    keywords: Option<String>,
    creator: Option<String>,
    producer: Option<String>,
    creation_date: Option<String>,
    mod_date: Option<String>,
}

#[rustler::nif(schedule = "DirtyCpu")]
fn process(bytes: Binary, options: Options) -> Result<Extraction, String> {
    let mode = match options.mode {
        Mode::Full => ProcessMode::Full,
        Mode::Detect => ProcessMode::DetectOnly,
        Mode::Analyze => ProcessMode::Analyze,
    };
    let profile = match options.profile {
        Profile::Fidelity => MarkdownProfile::Fidelity,
        Profile::Compact => MarkdownProfile::Compact,
    };
    let mut pdf_options = PdfOptions::new().mode(mode).markdown(MarkdownOptions {
        profile,
        include_page_numbers: options.page_breaks,
        ..MarkdownOptions::default()
    });

    if let Some(pages) = options.pages {
        pdf_options = pdf_options.pages(pages);
    }
    if let Some(password) = options.password {
        pdf_options = pdf_options.password(password);
    }

    let result = process_pdf_mem_with_options(bytes.as_slice(), pdf_options)
        .map_err(|error| error.to_string())?;

    Ok(Extraction {
        markdown: result.markdown,
        pdf_type: match result.pdf_type {
            PdfType::TextBased => atoms::text_based(),
            PdfType::Scanned => atoms::scanned(),
            PdfType::ImageBased => atoms::image_based(),
            PdfType::Mixed => atoms::mixed(),
        },
        page_count: result.page_count,
        processing_time_ms: result.processing_time_ms,
        confidence: result.confidence,
        pages_needing_ocr: result.pages_needing_ocr,
        has_encoding_issues: result.has_encoding_issues,
        title: result.title,
        author: result.author,
        subject: result.subject,
        keywords: result.keywords,
        creator: result.creator,
        producer: result.producer,
        creation_date: result.creation_date,
        mod_date: result.mod_date,
    })
}

rustler::init!("Elixir.PdfInspector.Native");
