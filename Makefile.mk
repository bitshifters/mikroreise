ifeq ($(OS),Windows_NT)
RM_RF:=-cmd /c rd /s /q
MKDIR_P:=-cmd /c mkdir
COPY:=copy
VASM?=bin\vasmarm_std_win32.exe
VLINK?=bin\vlink.exe
LZ4?=bin\lz4.exe
SHRINKLER?=bin\Shrinkler.exe
PYTHON2?=C:\Dev\Python27\python.exe
PYTHON3?=python.exe
DOS2UNIX?=bin\dos2unix.exe
else
RM_RF:=rm -Rf
MKDIR_P:=mkdir -p
COPY:=cp
VASM?=vasmarm_std
VLINK?=vlink
LZ4?=lz4
SHRINKLER?=shrinkler
PYTHON3?=python
DOS2UNIX?=dos2unix
endif
# TODO: Add Lua code and table gen to dependencies.

PNG2ARC=./bin/png2arc.py
PNG2ARC_FONT=./bin/png2arc_font.py
PNG2ARC_SPRITE=./bin/png2arc_sprite.py
PNG2ARC_DEPS:=./bin/png2arc.py ./bin/arc.py ./bin/png2arc_font.py ./bin/png2arc_sprite.py
FOLDER=!Reise
HOSTFS=../arculator/hostfs
# TODO: Need a copy command that copes with forward slash directory separator. (Maybe MSYS cp?)

##########################################################################
##########################################################################

.PHONY:deploy
deploy: $(FOLDER)
	$(RM_RF) "$(HOSTFS)\$(FOLDER)"
	$(MKDIR_P) "$(HOSTFS)\$(FOLDER)"
	$(COPY) "$(FOLDER)\*.*" "$(HOSTFS)\$(FOLDER)\*.*"

$(FOLDER): build ./build/archie-verse.bin ./build/seq.bin ./build/!run.txt ./build/icon.bin ./build/three-dee.mod
	$(RM_RF) $(FOLDER)
	$(MKDIR_P) $(FOLDER)
	$(COPY) .\folder\*.* "$(FOLDER)\*.*"
	$(COPY) .\build\!run.txt "$(FOLDER)\!Run,feb"
	$(COPY) .\build\icon.bin "$(FOLDER)\!Sprites,ff9"
	$(COPY) .\build\archie-verse.bin "$(FOLDER)\!RunImage,ff8"
	$(COPY) .\build\three-dee.mod "$(FOLDER)\Music,001"
	$(COPY) .\build\seq.bin  "$(FOLDER)\Seq,ffd"

.PHONY:seq
seq: ./build/seq.bin
	$(COPY) .\build\seq.bin  "$(FOLDER)\Seq,ffd"
	$(COPY) "$(FOLDER)\Seq,ffd" "$(HOSTFS)\$(FOLDER)"

.PHONY:compress
compress: shrink
	$(RM_RF) "$(HOSTFS)\$(FOLDER)"
	$(MKDIR_P) "$(HOSTFS)\$(FOLDER)"
	$(COPY) "$(FOLDER)\*.*" "$(HOSTFS)\$(FOLDER)\*.*"

.PHONY:shrink
shrink: build ./build/archie-verse.shri ./build/seq.bin ./build/!run.txt ./build/icon.bin ./build/loader.bin ./build/three-dee.mod
	$(RM_RF) $(FOLDER)
	$(MKDIR_P) $(FOLDER)
	$(COPY) .\folder\*.* "$(FOLDER)\*.*"
	$(COPY) .\build\!run.txt "$(FOLDER)\!Run,feb"
	$(COPY) .\build\icon.bin "$(FOLDER)\!Sprites,ff9"
	$(COPY) .\build\loader.bin "$(FOLDER)\!RunImage,ff8"
	$(COPY) .\build\three-dee.mod "$(FOLDER)\Music,001"
	$(COPY) .\build\archie-verse.shri "$(FOLDER)\Demo,ffd"
	$(COPY) .\build\seq.bin  "$(FOLDER)\Seq,ffd"

build:
	$(MKDIR_P) "./build"

./build/assets.txt: build ./build/icon.bin ./build/bs-logo.bin ./build/tmt-logo.bin ./build/credits.bin
	echo done > $@

./build/archie-verse.shri: build ./build/archie-verse.bin
	$(SHRINKLER) -b -d -p -z -1 ./build/archie-verse.bin $@

./build/loader.bin: build ./src/loader.asm
	$(VASM) -L build\loader.txt -m250 -Fbin -opt-adr -D_USE_SHRINKLER=1 -o $@ ./src/loader.asm

./build/seq.bin: build ./build/seq.o link_script2.txt
	$(VLINK) -T link_script2.txt -b rawbin1 -o $@ build/seq.o -Mbuild/linker2.txt

./build/seq.o: build archie-verse.asm ./src/sequence-data.asm ./build/three-dee.mod ./build/assets.txt
	$(VASM) -L build/compile.txt -m250 -Fvobj -opt-adr -o build/seq.o archie-verse.asm

./build/archie-verse.bin: build ./build/archie-verse.o ./build/seq.o link_script.txt
	$(VLINK) -T link_script.txt -b rawbin1 -o $@ build/archie-verse.o -Mbuild/linker.txt

./build/dot_gen_code_a.bin: ./src/dot_plot_generated.asm
	$(VASM) -L build/dot_a.txt -m250 -Fbin -opt-adr -o $@ $<

./build/dot_gen_code_b.bin: ./src/dot_plot_generated_b.asm
	$(VASM) -L build/dot_b.txt -m250 -Fbin -opt-adr -o $@ $<

.PHONY:./build/archie-verse.o
./build/archie-verse.o: build archie-verse.asm ./build/three-dee.mod ./build/assets.txt ./build/dot_gen_code_a.bin ./build/dot_gen_code_b.bin
	$(VASM) -L build/compile.txt -m250 -Fvobj -opt-adr -o build/archie-verse.o archie-verse.asm

##########################################################################
##########################################################################

.PHONY:clean
clean:
	$(RM_RF) "build"
	$(RM_RF) "$(FOLDER)"

##########################################################################
##########################################################################

./build/logo.lz4: ./build/logo.bin
./build/logo.bin: ./data/gfx/chipodjangofina-10colors-216x68.png ./data/logo-palette-hacked.bin $(PNG2ARC_DEPS)
	$(PYTHON2) $(PNG2ARC) -o $@ --use-palette data/logo-palette-hacked.bin -m $@.mask --mask-colour 0x00ff0000 --loud $< 9

./build/big-font.bin: ./data/font/font-big-finalFINAL.png $(PNG2ARC_DEPS)
	$(PYTHON2) $(PNG2ARC_FONT) -o $@ --glyph-dim 16 16 $< 9

./build/icon.bin: ./data/gfx/mikroreise_icon.png $(PNG2ARC_DEPS)
	$(PYTHON2) $(PNG2ARC_SPRITE) --name !reise -o $@ $< 9

./build/bs-logo.bin: ./data/gfx/BITSHIFERS-logo-anaglyph.png $(PNG2ARC_DEPS)
	$(PYTHON2) $(PNG2ARC) -o $@ -p $@.pal $< 9

./build/tmt-logo.bin: ./data/gfx/TORMENT-logo-anaglyph.png $(PNG2ARC_DEPS)
	$(PYTHON2) $(PNG2ARC) -o $@ -p $@.pal $< 9

./build/credits.bin: ./data/gfx/crew-credits2.png $(PNG2ARC_DEPS)
	$(PYTHON2) $(PNG2ARC) -o $@ -p $@.pal $< 9

##########################################################################
##########################################################################

./build/three-dee.mod: ./data/music2/mikroreise.mod
	$(COPY) $(subst /,\\,$+) $(subst /,\\,$@)

##########################################################################
##########################################################################

./build/!run.txt: ./data/text/!run.txt
	$(DOS2UNIX) -n $< $@

##########################################################################
##########################################################################

# Rule to convert PNG files, assumes MODE 9.
%.bin : %.png $(PNG2ARC_DEPS)
	$(PYTHON2) $(PNG2ARC) -o $@ -p $@.pal $< 9

# Rule to LZ4 compress bin files.
%.lz4 : %.bin
	$(LZ4) --best -f $< $@

# Rule to Shrinkler compress bin files.
%.shri : %.bin
	$(SHRINKLER) -d -b -p -z $< $@

# Rule to copy MOD files.
%.bin : %.mod
	$(COPY) $(subst /,\\,$+) $(subst /,\\,$@)

##########################################################################
##########################################################################
