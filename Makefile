CC = g++
CFLAGS = -std=c++17
LIBS = -ljsoncpp

SRCS = lmt_test.cpp
OBJS = $(SRCS:.cpp=.o)
EXECUTABLE = lmt

all: $(EXECUTABLE)

$(EXECUTABLE): $(OBJS)
	$(CC) $(CFLAGS) $(OBJS) -o $(EXECUTABLE) $(LIBS)

.cpp.o:
	$(CC) $(CFLAGS) -c $< -o $@

clean:
	rm -f $(OBJS) $(EXECUTABLE)
