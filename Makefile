dataprep:
	Rscript --vanilla --verbose 03_code/1_download_data.R
	Rscript --vanilla --verbose 03_code/2_data_prep.R

figs:
	Rscript --vanilla --verbose 03_code/3_maps.R
	Rscript --vanilla --verbose 03_code/4_charts.R
	
html:
	quarto render 04_docs/Website/essay.Rmd
	mv 04_docs/Website/essay.html index.html
	
pdf:
	cd 04_docs/Latex/ && \
	pdflatex --shell-escape -interaction=batchmode Essay.tex && \
	pdflatex --shell-escape -interaction=batchmode Essay.tex && \
	bibtex Essay.aux && \
	pdflatex --shell-escape -interaction=batchmode Essay.tex && \
	pdflatex --shell-escape -interaction=batchmode Essay.tex
	rm 04_docs/Latex/Essay.log \
		 04_docs/Latex/Essay.aux \
		 04_docs/Latex/Essay.out \
		 04_docs/Latex/Essay.bbl \
		 04_docs/Latex/Essay.blg

slides:
	quarto render 04_docs/Presentation/slides.qmd
	mv 04_docs/Presentation/slides.html slides.html