# caulobrowser 0.8.0

* Fixes CauloChat bug and improves system prompts.
* Improves CauloChat reactable table styling.
* Fixes Docker container system dependency issues.

# caulobrowser 0.7.0

- Adds the alpha version of the CauloChat feature.

# caulobrowser 0.6.0

- Adds mRNA and protein quantification data types to the expression browser.
- Updates database schema to support quantification data.
- Bundles an example DuckDB database in `inst/extdata` for offline development and testing; removes the standalone `generate_example_database()` export.
- Splits Docker build into separate base and runtime images to speed up CI builds.
- Skips package build and tests in CI when no package files changed.
- Updated R dependencies.

# caulobrowser 0.5.0

- Added fitness data from [Price, M.N., Wetmore, K.M., Waters, R.J. et al.](https://www.nature.com/articles/s41586-018-0124-0#Abs1)
- Updated dependencies.

# caulobrowser 0.4.0

- Adds filter controls to the differential expression heatmap.
- Adds GitHub Actions CI: automated Docker image publishing, R CMD check, and test coverage reporting on pull requests and pushes.
- Expands test coverage across database query functions.

# caulobrowser 0.3.0

- Adds operon track to the genome viewer.
- Docker image now includes the Pelican binary to support programmatic database download.

# caulobrowser 0.2.3

- Switches genome viewer track data storage from AWS to OSN (Open Storage Network) pod.

# caulobrowser 0.2.1

- Fixes JBrowseR genome viewer not launching when the tab is clicked directly.

# caulobrowser 0.2.0

- Splits the data section into separate Expression Browser and Fitness Browser tabs.
- Expands the Gene Overview table with additional annotation fields.
- Adds STRING and PaperBlast links to the Gene Overview table.
- Adds a link from the Gene Overview table to the genome viewer for the selected gene.
- Updates the genes table schema and GFF indexes for the genome viewer.

# caulobrowser 0.1.2

- Adds gene feature index to improve [JBrowseR](https://gmod.org/JBrowseR/index.html) genome viewer performance.

# caulobrowser 0.1.1

- Adds [JBrowseR](https://gmod.org/JBrowseR/index.html) as the genome viewer tool.
- Fixes JBrowseR viewer layout and resolves a runtime dependency on `libssl`.

# caulobrowser 0.1.0

- Initial release.
- Interactive expression timecourse plots with experiment details (ggiraph).
- Differential expression heatmaps with experiment details.
- Gene Overview table with collapsible sections.
- Gene search by locus tag, legacy tag, or gene name.
- Docker builds and justfile for convenience commands.
