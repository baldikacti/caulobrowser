# caulobrowser 0.5.0

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
