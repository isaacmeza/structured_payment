version 17.0

* Static appendix assets supplied with the replication files. These checks
* fail if an asset is missing or differs from the bundled manuscript input.
confirm file "$directorio/Figures/FigureOA1.png"
quietly checksum "$directorio/Figures/FigureOA1.png"
assert r(filelen) == 333811
assert r(checksum) == 3215446456

confirm file "$directorio/Tables/TableOA7.tex"
quietly checksum "$directorio/Tables/TableOA7.tex"
assert r(filelen) == 5084
assert r(checksum) == 1960257307
