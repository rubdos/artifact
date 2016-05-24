use std::path::Path;

mod types;
mod vars;
#[macro_use] mod load;  // macro use so the macro can be tested
mod link;

#[cfg(test)]
mod tests;

pub use core::types::{
    LoadResult, LoadError,
    Artifacts, Artifact, ArtType, ArtName, Loc,
    Settings};
// use core::load;

/// do all core loading operations defined in SPC-core-load-parts
/// includes loading and validating raw data, resolving and applying
/// variables, and linking artifacts
pub fn load_path(path: &Path) -> LoadResult<(Artifacts, Settings)>{
    let (mut artifacts, settings) = try!(load::load_path(path));

    Ok((artifacts, settings))
}

    // TODO: LOC-core-load-parts-2:<load and validate global variables>
    // LOC-core-load-parts-3:<resolve variables in text fields>
    // LOC-core-load-parts-4:<auto-creation of missing prefix artifacts>
    // LOC-core-load-parts-5:<linking of artifacts>
