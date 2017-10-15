CXX=moonc
FLAGS=-t dist


all:
	@echo Hello

build-win:
	$(CXX) $(FLAGS) ./src/*
	cmd /C "for /R ./dist %F in (*) do move /Y %F ./dist"
