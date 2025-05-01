FLAGS=-shell-escape -pdf
ENV = LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8

report:
	$(ENV) latexmk $(FLAGS) main.tex

interactive:
	$(ENV) latexmk $(FLAGS) -pvc main.tex

clean:
	latexmk -C

spell:
	aspell -c -t 

count: SHELL:=/bin/bash
count:
	 @texcount $(shell find . -name '*.tex')
