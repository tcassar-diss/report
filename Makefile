FLAGS=-shell-escape -pdf


report:
	latexmk $(FLAGS) main.tex

interative:
	latexmk $(FLAGS) -pvc main.tex

clean:
	latexmk -C

spell:
	aspell -c -t 

count: SHELL:=/bin/bash
count:
	 @texcount $(shell find . -name '*.tex')
