# 🔢 Choosing thresholds

Thresholds define **groups for downstream analysis** like [**PoODLE**](https://github.com/MDHHS-Bioinformatics/poodle) (hqSNPs, recombination filtering, pangenome comparisons). 

These groups are **not strict “clusters”**, since they can include contextual samples to maintain lineage-level resolution.

| Threshold | Use case                         |
| --------- | -------------------------------- |
| 15–20     | Tight clusters (high-resolution) |
| 40        | General clustering               |
| 150       | Broad lineage grouping           |


# cgMLST Allelic Distance (AD) Thresholds – Reference

> 💡 Ideal group size: **≥4 samples**
> If your group becomes too large, **lower the threshold** to retain only the most strongly related isolates.
AD thresholds are species-specific and depend on the scale desired. General overview:

| Scale                   | Typical AD range           |
| ----------------------- | -------------------------- |
| Outbreak / transmission | 0–25 AD (species-specific) |
| ST-level structure      | 100–700+ AD                |
| CC / lineage structure  | 300–2000+ AD               |


## 1. Thresholds from Mixão et al., *Nature Communications* (2025)

**Reference:**
Mixão V. *et al.*
*Clustering stability and congruence across bacterial cgMLST pipelines*
Nature Communications (2025)
DOI: 10.1038/s41467-025-59246-8

### 1.1 Per-species congruence thresholds (ADs)

| Species                  | ST Congruence (AD)              | CC / Serotype Congruence (AD)                | Outbreak-Level Notes                                                                                                 | PopPUNK Congruence |
| ------------------------ | ------------------------------- | -------------------------------------------- | -------------------------------------------------------------------------------------------------------------------- | ------------------ |
| *Listeria monocytogenes* | ~143–190                        | ~388–508                                     | Outbreak clusters commonly assessed at **7 AD** (4 AD stringent); flexible up to ~9 AD improves pipeline concordance | -      |
| *Salmonella enterica*    | ~205–310                        | ~1261–1663 (serotype)                        | 10-14 ADs                                                                    | -       |
| *Escherichia coli*       | ~545–738                        | Not clearly separated from serotype          | 9 AD                                                                           | ~723–1002 AD       |
| *Campylobacter jejuni*   | -        | ~315–522 (short schemas); ~644–839 (PubMLST) | 4 ADs                                                                                    | -  |

---

## 2. cgMLST.org / Ridom SeqSphere+ Complex Thresholds

**Source:**
cgmlst.org species schemes and Ridom SeqSphere+ default cluster definitions
(thresholds typically used for **outbreak / complex detection**)

These thresholds define **maximum allelic distances** for assigning isolates to the same cgMLST complex or cluster.

### 2.1 Species-specific outbreak / complex thresholds

| Scheme                                                        | Complex Type Distance (AD) |
| ------------------------------------------------------------- | -------------------------- |
| *Acinetobacter baumannii* cgMLST                              | 9                          |
| *Bacillus anthracis* cgMLST                                   | 5                          |
| *Bordetella pertussis* cgMLST                                 | 6                          |
| *Brucella melitensis* cgMLST                                  | 6                          |
| *Brucella* spp. cgMLST                                        | 3                          |
| *Burkholderia mallei* (FLI) cgMLST                            | 3                          |
| *Burkholderia mallei* (RKI) cgMLST                            | 3                          |
| *Burkholderia pseudomallei* cgMLST                            | 5                          |
| *Campylobacter jejuni/coli* cgMLST                            | 13                         |
| *Citrobacter freundii* cgMLST                                 | 10                         |
| *Citrobacter freundii* 2 cgMLST                               | 8                          |
| *Clostridioides difficile* cgMLST                             | 6                          |
| *Clostridium perfringens* cgMLST                              | 7                          |
| *Corynebacterium diphtheriae* cgMLST                          | 14                         |
| *Corynebacterium pseudotuberculosis* cgMLST                   | 10                         |
| *Cronobacter sakazakii/malonaticus* cgMLST                    | 10                         |
| *Enterobacter hormaechei* cgMLST                              | 12                         |
| *Enterococcus faecalis* cgMLST                                | 7                          |
| *Enterococcus faecium* cgMLST                                 | 20                         |
| *Escherichia coli* cgMLST                                     | 10                         |
| *Francisella tularensis* cgMLST                               | 1                          |
| *Klebsiella oxytoca/grimontii/michiganensis/pasteurii* cgMLST | 9                          |
| *Klebsiella pneumoniae/variicola/quasipneumoniae* cgMLST      | 15                         |
| *Legionella pneumophila* cgMLST                               | 4                          |
| *Listeria monocytogenes* cgMLST                               | 10                         |
| *Morganella morganii* cgMLST                                  | 10                         |
| *Mycobacterium tuberculosis/bovis/africanum/canettii* cgMLST  | 12                         |
| *Mycobacteroides abscessus* cgMLST                            | 24                         |
| *Mycoplasma gallisepticum* cgMLST                             | 10                         |
| *Paenibacillus larvae* cgMLST                                 | 10                         |
| *Proteus mirabilis* cgMLST                                    | 45                         |
| *Providencia stuartii* cgMLST                                 | 15                         |
| *Pseudomonas aeruginosa* cgMLST                               | 12                         |
| *Salmonella enterica* cgMLST                                  | 7                          |
| *Serratia marcescens* cgMLST                                  | 12                         |
| *Staphylococcus argenteus* cgMLST                             | 20                         |
| *Staphylococcus aureus* cgMLST                                | 24                         |
| *Staphylococcus capitis* cgMLST                               | 23                         |
| *Streptococcus pyogenes* cgMLST                               | 5                          |
| *Yersinia enterocolitica* cgMLST                              | 4                          |

---

