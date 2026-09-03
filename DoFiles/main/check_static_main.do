version 17.0

* Figure 2 is a static manuscript asset with an editable Excel source.
local pdf "$directorio/Figures/Figure2.pdf"
local xlsx "$directorio/Figures/ToT-TUT graph.xlsx"

confirm file "`pdf'"
quietly checksum "`pdf'"
if r(checksum) != 4261103016 | r(filelen) != 60358 {
    display as error "Figure 2 PDF does not match the approved static asset."
    exit 9
}

confirm file "`xlsx'"
quietly checksum "`xlsx'"
if r(checksum) != 3501859171 | r(filelen) != 13028 {
    display as error "Figure 2 editable workbook does not match the approved source asset."
    exit 9
}

display as result ///
    "Figure 2 static PDF and editable workbook verified; neither file was rewritten."
