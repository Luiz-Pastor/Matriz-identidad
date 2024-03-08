all: pract2.exe

pract2.exe: pract2.obj
	tlink /v pract2

pract2.obj: pract2.asm
	tasm /zi pract2.asm

clean:
	@del PRACT2.EXE
	@del PRACT2.MAP
	@del PRACT2.OBJ

r: clean all
	./pract2.exe