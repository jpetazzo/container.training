workshop.html:

%.html: %.yml *.md workshop.html
	./markmaker.py < $< > $@ || rm $@
	# open $@
