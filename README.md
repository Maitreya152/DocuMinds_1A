# README

# Round 1A: Understand Your Document

Note: The GitHub link associated with this submission is currently kept private, in order to abide by the contest instructions. Though, this zip file is self sufficient. The GitHub link can be made public once asked to do so.

## Approach

We build the outline progressively through various levels of parsing and clustering the text in the document. We mainly cluster the text as headings and body (non-headings). The steps are as follows:

### 1. **Text Feature Extraction**
- **PyMuPDF (`fitz`)** is used to extract fonts, bounding boxes, and styling (bold, italic, colour, font-size) and other attributes every line in the document. A line is defined by the list of span of text detected by **PyMuPDF (`fitz`)**.
- **pdfplumber** is used to detect tables and images which are to be excluded from the outline.
- Using the features extracted other features pertaining to the text like word count, spacing above/below lines are deduced which help to distinguish headings from body text of the document.

### 2. **Initial Heuristic Body Text Identification**
- The text lines are initially classified as body text using **universal heuristics** like:
    - Heading cannot start with special characters like braces, bullets etc.
    - Web links etc cannot be a heading.
- Few more heuristics are introduced to filter the text which cannot belong to the outline as headings like:
  - Word count thresholds : Number of words in the heading should be lesser than the average word count in a line of a document.
  - Font size deviation from modal size : The font size of the heading should be greater than or equal to the mode font size of the text in the whole document.
  - Bold attribute : Bold formatting can be a likely signal that a text is a heading, but it is not a sufficient condition on its own.
  - Colour attribute : If a text has the colour same as the mode colour of the full document text, then it is likely that it is not a heading.
    
    As none of these heuristics are sufficient conditions by themselves, combining all of them together helps to form a strong condition to detect whether a particular line of the document necessarily cannot belong to heading. The conditions are as follows:
    - **Condition 1**: If the word count threshold is not satisfied and the text is not bold, then it is not a heading text.
    - **Condition 2**: If the font size of the text is same as the mode font size, the text is not bold then it is necessary for the text to have different font-colour than the mode colour for it to classify as a heading, else it belongs to the body of the document.

### 3. **Clustering Headings**
- After filtering the text with some manual checks, **DBSCAN (Density-Based Spatial Clustering of Applications with Noise)** clustering is applied using `font_size` and `bold` as features to be used for clustering. The features are normalized using `StandardScaler`.
- **DBSCAN** is an unsupervised clustering algorithm that groups together points that are closely packed based on a density threshold (eps=0.2) and a minimum number of samples (min_samples=1). It is particularly effective in identifying clusters of varying shapes and sizes, and it can also classify outliers as noise (assigned label -1). This makes it well-suited for separating headings (which often differ in font styling) from body text.
- Thus, the clusters obtained are assigned as the headings which are generally well-clustered according to their heading levels.

### 4. **Refining the Output from DBSCAN Clustering**
- Elements like **non-bordered tables** or **misaligned text blocks** may accidentally be clustered as headings. These are filtered out using geometric heuristics that is specifically, line alignment and vertical proximity based on bounding box coordinates as obtained by  **PyMuPDF (`fitz`)**. If multiple lines on the same page align horizontally and are close vertically (within a defined threshold), they're likely part of a table or body content rather than true headings.
- In many documents, especially scanned or complex PDFs, a **heading might wrap across multiple lines**. To address this, a line merging algorithm is applied that connects adjacent lines that belong to the same cluster and are on the same page, vertically proximate (parameter: threshold_v, default_value: 15 units) and horizontally aligned with overlapping or closely matched widths (parameter: threshold_h, default_value: 1 unit). This process involves building a graph where each line is a node, and edges are added based on the proximity rules above. We then use Breadth-First Search (BFS) to extract connected components, which are merged into a single line with combined text and an updated bounding box.

### 5. **Heading Levels Assignment**
- Headings are grouped by cluster and Cluster font size determines heading level as follows:
  - Largest font cluster → H1
  - Next → H2, and so on.
 The title is identified as the first line from the highest-ranking heading cluster (i.e., the one with the largest average font size) and is typically the first prominent text appearing in the document. 


Thus by **extracting and analyzing** font size, font type, color, and spacing between lines, **identifying headings** based on typography and layout using clustering (DBSCAN), **detect tables and images**, including handling of 1×1 tables and image bounding boxes we can **generates a structured JSON outline** of the document, including title and headings with hierarchy.

---

## Models and Libraries Used

| Library        | Purpose                                      |
|----------------|----------------------------------------------|
| `PyMuPDF (fitz)` | Text layout and style extraction            |
| `pdfplumber`   | Table and image extraction                   |
| `scikit-learn` | DBSCAN clustering, normalization             |
| `NumPy`        | Numerical operations                         |
| `Matplotlib`   | (Optional) visualization                     |
| `collections`  | Counting, default dicts, deques              |
| `os`, `pathlib`| File system and path management              |
| `re`           | Regex for text classification                |
| `json`         | Output serialization                         |

---

## How to build and run the solution 

The Docker image can be built using the following command:

```bash
docker build --platform linux/amd64 -t your_identifier .
```

After building the image, the solution can be run using the following command:

```bash
docker run --rm -v "$(pwd)/input:/app/input" -v "$(pwd)/output:/app/output" --network none your_identifier
```

Your container should:

*   Automatically process all PDFs from `./input` directory, generating a corresponding `file_name.json` in `./output` directory. Note that the page number is 1 indexed.

*   Output the total and average processing time taken by the documents.
Example: ```Total processing time for 5 successful files: 8.55 seconds
Average processing time per file: 1.71 seconds``` This is for the 5 files already present in ./input