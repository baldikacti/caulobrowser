# caulobrowser 0.2.2

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
