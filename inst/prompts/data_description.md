## Database Overview

CauloBrowser is a curated systems biology resource for *Caulobacter crescentus* NA1000, a gram-negative model organism used to study bacterial cell differentiation, the cell cycle, and gene regulation. The database integrates genome annotations with high-throughput experimental datasets including RNA-seq transcriptomics, Tn-seq fitness screens, and quantitative proteomics.

There are two historical locus tag systems for *C. crescentus*:
- **CCNA_XXXXX** tags (e.g., `CCNA_00001`) — NA1000 strain locus tags; this is the primary key used throughout the database (`gene_id`)
- **CC_XXXX** tags (e.g., `CC_0001`) — CB15 strain legacy tags found in older literature (`cc_tag`)

---

## Table Schemas and Column Descriptions

### `genes` — Gene Annotations

Primary annotation table. One row per gene in the NA1000 genome.

| Column | Type | Description |
|--------|------|-------------|
| `gene_id` | VARCHAR | **Primary key.** CCNA_XXXXX NA1000 locus tag (e.g., `CCNA_00001`). Used to join with `de_results` and `timecourse_expression`. |
| `cc_tag` | VARCHAR | CB15 legacy locus tag (CC_XXXX format). Appears in older literature. May be NULL for genes without a CB15 equivalent. |
| `gene_name` | VARCHAR | Short gene name (e.g., `ftsZ`, `dnaA`, `ctrA`). Will contain the CCNA locus tag if the short name does not exist. |
| `uniprot_id` | VARCHAR | UniProt accession number for the encoded protein. |
| `start_pos` | BIGINT | Start position (bp) on the NA1000 chromosome (1-based, inclusive). |
| `end_pos` | BIGINT | End position (bp) on the NA1000 chromosome (1-based, inclusive). |
| `strand` | VARCHAR | Genomic strand: `+` (forward/sense) or `-` (reverse/antisense). |
| `length` | VARCHAR | Gene length in base pairs. |
| `mass` | VARCHAR | Predicted protein mass in kDa. |
| `copynumber_lifetime_min` | DOUBLE | Transcription rate in minutes (M2G media) (quantitative proteomics). |
| `copynumber` | DOUBLE | mRNA Copy Number per Cell in minutes (M2G media) (quantitative proteomics). |
| `translated_prot_ave` | DOUBLE | Molecules translated per cell (M2G media). |
| `mrna_halflife` | DOUBLE | mRNA half-life in minutes. |
| `gene_biotype` | VARCHAR | Gene class: `protein_coding`, `tRNA`, `rRNA`, `ncRNA`, or other biotypes. |
| `product` | VARCHAR | Short functional product description (e.g., `cell division protein FtsZ`). |
| `description` | VARCHAR | Longer functional description of the gene or protein. |
| `protein_names` | VARCHAR | Full protein name(s) from UniProt, including alternative names. |
| `function_cc` | VARCHAR | Curated function comment from UniProt. |
| `protein_families` | VARCHAR | Protein family or superfamily classification. |
| `essential` | VARCHAR | Essentiality classification: `essential` (required for growth), `non-essential`, or NULL if unknown. Based on Tn-seq fitness screens. |
| `Dbxref` | VARCHAR | Cross-references to external databases (pipe-separated). |
| `existence_ncbi` | VARCHAR | Protein existence evidence level from NCBI. |
| `existence_uniprot` | VARCHAR | Protein existence evidence level from UniProt: 1 = protein evidence, 2 = transcript, 3 = homology inference, 4 = predicted, 5 = uncertain. |
| `COG` | VARCHAR | COG (Clusters of Orthologous Groups) identifier. |
| `COGFun` | VARCHAR | COG functional category letter code(s). Common values: `J` (translation), `K` (transcription), `L` (replication/repair), `D` (cell division), `M` (cell wall), `N` (motility), `O` (chaperones), `P` (inorganic ion transport), `Q` (secondary metabolism), `T` (signal transduction), `U` (intracellular trafficking), `C` (energy), `E` (amino acid metabolism), `F` (nucleotide metabolism), `G` (carbohydrate metabolism), `H` (coenzyme metabolism), `I` (lipid metabolism), `R` (general function), `S` (unknown). |
| `COGDesc` | VARCHAR | Full description of the COG functional category. |
| `TIGRFam` | VARCHAR | TIGRFAM family identifier(s). |
| `TIGRRoles` | VARCHAR | TIGRFAM role classification. |
| `GO` | VARCHAR | Gene Ontology term IDs and names (semicolon-separated). |
| `KEGG` | VARCHAR | KEGG orthology (K number) and pathway identifiers. |
| `activity_regulation` | VARCHAR | Regulatory information from UniProt (e.g., inhibitors, activators, post-translational regulation). |
| `rhea_id` | VARCHAR | Rhea biochemical reaction database ID for enzyme-catalyzed reactions. |
| `interacts` | VARCHAR | Known protein-protein interaction partners (gene names, semicolon-separated). |
| `subcellular_location_cc` | VARCHAR | Subcellular localization from UniProt (e.g., `Cell membrane`, `Cytoplasm`, `Cell pole`, `Flagellum`). |
| `ptm` | VARCHAR | Post-translational modification annotations (phosphorylation, methylation, etc.). |
| `pubmed_id` | VARCHAR | PubMed IDs of relevant publications. |
| `doi` | VARCHAR | DOI(s) of relevant publications. |
| `EMBL` | VARCHAR | EMBL/GenBank nucleotide accession. |
| `protein_id` | VARCHAR | NCBI protein accession number. |
| `PDB` | VARCHAR | Protein Data Bank structure IDs (experimentally solved structures). |
| `SMR` | VARCHAR | SWISS-MODEL Repository homology model IDs. |
| `sequence_similarities` | VARCHAR | Sequence similarity annotations from UniProt. |
| `protein_sequence` | VARCHAR | Full amino acid sequence (single-letter code). |

---

### `experiments` — Experimental Metadata

One row per experiment (a comparison or timecourse). All expression and fitness data links back here via `experiment_id`.

| Column | Type | Description |
|--------|------|-------------|
| `experiment_id` | VARCHAR | **Primary key.** Unique experiment identifier. Used to join with `de_results`, `timecourse_expression`, and `experiment_conditions`. |
| `display_label` | VARCHAR | Human-readable experiment name shown in the app. |
| `experiment_class` | VARCHAR | Broad experimental design: `timecourse` (cell cycle synchronized. Related to `timecourse_expression` table) and `de_comparison` (Experiments comparing one condition to another. Relates to `de_results` table.). |
| `data_type` | VARCHAR | Data modality: `rnaseq` (RNA-seq transcriptomics), `tnseq` (Tn-seq fitness/essentiality), `proteomics` (quantitative mass spectrometry), `ribosome_profiling` (translation efficiency). |
| `strain` | VARCHAR | Bacterial strain used (e.g., `NA1000`). |
| `genetic_background` | VARCHAR | Genetic background of the cell used in the experiment (e.g., `wildtype` for no modification or `∆clpB` for ClpB knockout, etc.). |
| `treatment` | VARCHAR | Experimental treatment applied (e.g., `heat`, `l-canavanine`, `D-Glucose carbon source`, `untreated`). |
| `treatment_level` | VARCHAR | Dose or intensity of the treatment. |
| `growth_phase` | VARCHAR | Bacterial growth phase at time of sampling (e.g., `mid-log`, `stationary`). |
| `media` | VARCHAR | Growth medium (e.g., `PYE` = peptone yeast extract rich medium, `M2G` = minimal glucose medium). |
| `ref_strain` | VARCHAR | Strain used as the reference/control condition for fold-change calculation. |
| `ref_treatment` | VARCHAR | Treatment applied to the reference/control condition. |
| `ref_treatment_level` | VARCHAR | Dose/level of the reference condition treatment. |
| `ref_growth_phase` | VARCHAR | Growth phase of the reference/control condition. |
| `ref_media` | VARCHAR | Growth medium of the reference/control condition. |
| `stat_method` | VARCHAR | Statistical method used for differential analysis (e.g., `padj`, `t-statistic` or NULL). |
| `lab_group` | VARCHAR | Lab or research group that performed the experiment. |
| `doi` | VARCHAR | DOI of the publication that reported this experiment. |
| `geo_id` | VARCHAR | GEO (Gene Expression Omnibus) or other repository accession for raw data. |
| `date_added` | VARCHAR | Date the experiment was curated and added to the database. |

---

### `de_results` — Differential Expression / Fitness Results

One row per gene per experiment. Stores the outcome of statistical comparisons (RNA-seq fold-changes, Tn-seq fitness scores). The reference condition for each comparison is described in the `experiments` table (`ref_*` columns).

| Column | Type | Description |
|--------|------|-------------|
| `gene_id` | VARCHAR | **Composite PK. FK → genes.** |
| `experiment_id` | VARCHAR | **Composite PK. FK → experiments.** |
| `log2fc` | DOUBLE | Log2 fold-change of the experimental vs. reference condition. Positive = upregulated/fitness advantage; negative = downregulated/fitness disadvantage. |
| `stat_value` | DOUBLE | Statistical significance value. Meaning depends on `stat_method` in the experiments table: typically an adjusted p-value (padj) from DESeq2/edgeR, or a fitness score from Tn-seq analysis. |

**Join pattern:**
```sql
SELECT g.gene_name, g.product, d.log2fc, d.stat_value, e.display_label
FROM de_results d
JOIN genes g ON g.gene_id = d.gene_id
JOIN experiments e ON e.experiment_id = d.experiment_id
WHERE d.log2fc > 2 AND d.stat_value < 0.05
```

---

### `timecourse_expression` — Time-course / Condition Expression Values

One row per gene per experiment per condition. Stores absolute expression values for experiments with multiple timepoints or conditions (e.g., cell-cycle synchrony timecourses, multi-dose treatments).

| Column | Type | Description |
|--------|------|-------------|
| `gene_id` | VARCHAR | **Composite PK. FK → genes.** |
| `experiment_id` | VARCHAR | **Composite PK. FK → experiments.** |
| `condition_label` | VARCHAR | **Composite PK. FK → experiment_conditions.** Identifies the specific timepoint or condition within the experiment. |
| `expression_value` | DOUBLE | Normalized expression value. Units depend on `data_type`: TPM for RNA-seq; normalized intensity for proteomics. |

**Join pattern:**
```sql
SELECT g.gene_name, ec.condition_value, ec.condition_units, t.expression_value
FROM timecourse_expression t
JOIN genes g ON g.gene_id = t.gene_id
JOIN experiment_conditions ec ON ec.experiment_id = t.experiment_id
  AND ec.condition_label = t.condition_label
WHERE g.gene_name = 'ftsZ'
ORDER BY ec.condition_order
```

---

### `experiment_conditions` — Condition Metadata for Timecourses

Describes the individual timepoints or conditions within a timecourse experiment. Referenced by `timecourse_expression`.

| Column | Type | Description |
|--------|------|-------------|
| `experiment_id` | VARCHAR | **Composite PK. FK → experiments.** |
| `condition_label` | VARCHAR | **Composite PK.** Internal label matching `timecourse_expression.condition_label`. |
| `condition_order` | INTEGER | Display order of conditions (use for correct axis ordering in plots). |
| `condition_value` | DOUBLE | Numeric value of the condition (e.g., `30` for a 30-minute timepoint). |
| `condition_units` | VARCHAR | Units for `condition_value` (e.g., `minutes`, `hours`, `µg/mL`). |
| `display_label` | VARCHAR | Human-readable label for plots and tables (e.g., `30 min`). |

---

## Key Relationships

```
genes (gene_id)
  ├── de_results (gene_id, experiment_id)
  │     └── experiments (experiment_id)
  └── timecourse_expression (gene_id, experiment_id, condition_label)
        ├── experiments (experiment_id)
        └── experiment_conditions (experiment_id, condition_label)
```

## Common Query Patterns

- **Essential genes with high expression**: JOIN `genes` + `timecourse_expression` on `gene_id`, filter `genes.essential = 'essential'`
- **Strongly differentially expressed genes in a specific experiment**: JOIN `de_results` + `genes` on `gene_id`, filter on `experiment_id`, `log2fc`, and `stat_value`
- **Gene expression over the cell cycle**: JOIN `timecourse_expression` + `experiment_conditions` on `experiment_id` AND `condition_label`, ORDER BY `condition_order`
- **All experiments of a given data type**: query `experiments` filtering on `data_type` (e.g., `data_type = 'rnaseq'`)
- **Cross-experiment comparison for a gene**: JOIN `de_results` + `experiments` + `genes`, GROUP or filter by `experiment_id`
