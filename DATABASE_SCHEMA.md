# Database Schema

The app reads from a DuckDB database with six tables.

## genes

| Column | Type | Notes |
|--------|------|-------|
| `gene_id` | VARCHAR | PK — CCNA_XXXXX NA1000 locus tag |
| `cc_tag` | VARCHAR | CC_XXXX CB15 legacy tag |
| `gene_name` | VARCHAR | |
| `uniprot_id` | VARCHAR | |
| `start_pos` | BIGINT | |
| `end_pos` | BIGINT | |
| `strand` | VARCHAR | |
| `length` | VARCHAR | |
| `mass` | VARCHAR | |
| `gene_biotype` | VARCHAR | |
| `product` | VARCHAR | |
| `description` | VARCHAR | |
| `protein_names` | VARCHAR | |
| `function_cc` | VARCHAR | |
| `protein_families` | VARCHAR | |
| `essential` | VARCHAR | |
| `Dbxref` | VARCHAR | |
| `existence_ncbi` | VARCHAR | |
| `existence_uniprot` | VARCHAR | |
| `COG` | VARCHAR | |
| `COGFun` | VARCHAR | |
| `COGDesc` | VARCHAR | |
| `TIGRFam` | VARCHAR | |
| `TIGRRoles` | VARCHAR | |
| `GO` | VARCHAR | |
| `KEGG` | VARCHAR | |
| `activity_regulation` | VARCHAR | |
| `rhea_id` | VARCHAR | |
| `interacts` | VARCHAR | |
| `subcellular_location_cc` | VARCHAR | |
| `ptm` | VARCHAR | |
| `pubmed_id` | VARCHAR | |
| `doi` | VARCHAR | |
| `EMBL` | VARCHAR | |
| `protein_id` | VARCHAR | |
| `PDB` | VARCHAR | |
| `SMR` | VARCHAR | |
| `sequence_similarities` | VARCHAR | |
| `protein_sequence` | VARCHAR | |

## experiments

| Column | Type | Notes |
|--------|------|-------|
| `experiment_id` | VARCHAR | PK |
| `display_label` | VARCHAR | |
| `experiment_class` | VARCHAR | |
| `data_type` | VARCHAR | |
| `strain` | VARCHAR | |
| `genetic_background` | VARCHAR | |
| `treatment` | VARCHAR | |
| `treatment_level` | VARCHAR | |
| `growth_phase` | VARCHAR | |
| `media` | VARCHAR | |
| `ref_strain` | VARCHAR | |
| `ref_treatment` | VARCHAR | |
| `ref_treatment_level` | VARCHAR | |
| `ref_growth_phase` | VARCHAR | |
| `ref_media` | VARCHAR | |
| `stat_method` | VARCHAR | |
| `lab_group` | VARCHAR | |
| `doi` | VARCHAR | |
| `geo_id` | VARCHAR | |
| `date_added` | VARCHAR | |

## experiment_conditions

FK → `experiments`

| Column | Type | Notes |
|--------|------|-------|
| `experiment_id` | VARCHAR | PK (composite) |
| `condition_label` | VARCHAR | PK (composite) |
| `condition_order` | INTEGER | |
| `condition_value` | DOUBLE | |
| `condition_units` | VARCHAR | |
| `display_label` | VARCHAR | |

## de_results

FK → `genes`, `experiments`

| Column | Type | Notes |
|--------|------|-------|
| `gene_id` | VARCHAR | PK (composite) |
| `experiment_id` | VARCHAR | PK (composite) |
| `log2fc` | DOUBLE | NOT NULL |
| `stat_value` | DOUBLE | |

## timecourse_expression

FK → `genes`, `experiments`, `experiment_conditions(experiment_id, condition_label)`

| Column | Type | Notes |
|--------|------|-------|
| `gene_id` | VARCHAR | PK (composite) |
| `experiment_id` | VARCHAR | PK (composite) |
| `condition_label` | VARCHAR | PK (composite) |
| `expression_value` | DOUBLE | NOT NULL |

## gene_viewer_metadata

| Column | Type | Notes |
|--------|------|-------|
| `assembly` | VARCHAR | |
| `text_index` | VARCHAR[4] | |
| `tracks` | STRUCT(`experiment_id` VARCHAR, `track_type` VARCHAR, `https_paths` VARCHAR)[] | Array of structs |

## Indexes

| Index | Table |
|-------|-------|
| `experiment_id` | `de_results` |
| `gene_id` | `de_results` |
| `gene_id` | `timecourse_expression` |
| `experiment_id` | `timecourse_expression` |
| `(gene_id, experiment_id)` | `timecourse_expression` |
| `experiment_class` | `experiments` |
| `data_type` | `experiments` |
| `lab_group` | `experiments` |
