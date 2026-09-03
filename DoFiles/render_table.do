* AI disclosure: This file was created with AI assistance.
version 17.0

* Render one manuscript table from its direct Stata CSV output.
* Python writes to a temporary file first so a failed render cannot be mistaken
* for a current TEX fragment.
args table_id extra_argument
local valid_table 0
foreach valid_id in Table1 Table2 Table3 TableOA1 TableOA2 TableOA3 ///
        TableOA4 TableOA5 TableOA6 TableOA8 TableOA9 TableSA1 {
    if "`table_id'" == "`valid_id'" local valid_table 1
}
if "`extra_argument'" != "" | !`valid_table' {
    display as error ///
        "Usage: do DoFiles/render_table.do {Table1|Table2|Table3|TableOA1|TableOA2|TableOA3|TableOA4|TableOA5|TableOA6|TableOA8|TableOA9|TableSA1}"
    exit 198
}

local tex_file "`table_id'.tex"

local python_command "python3"
if "`c(os)'" == "Windows" local python_command "python"

tempfile rendered_table
capture erase "`rendered_table'"
shell `python_command' ///
    "$directorio/PythonScripts/render_tables.py" ///
    --table "`table_id'" --output-file "`rendered_table'"
confirm file "`rendered_table'"
copy "`rendered_table'" "$directorio/Tables/`tex_file'", replace
confirm file "$directorio/Tables/`tex_file'"
