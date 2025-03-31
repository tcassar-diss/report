report:
	latexmk -pdf main.tex

interative:
	latexmk -pdf -pvc main.tex

clean:
	latexmk -C

spell:
	aspell -c -t 
