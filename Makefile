CC = g++
CFLAGS = -std=c++17
LIBS = -ljsoncpp

SRCS = lmt.cpp
TEST_SRCS = lmt_test.cpp
OBJS = $(SRCS:.cpp=.o)
TEST_OBJS = $(TEST_SRCS:.cpp=.o)
EXECUTABLE = lmt
TEST_EXECUTABLE = lmt_test

all: $(EXECUTABLE)

$(EXECUTABLE): $(OBJS)
	$(CC) $(CFLAGS) $(OBJS) -o $(EXECUTABLE) $(LIBS)

.cpp.o:
	$(CC) $(CFLAGS) -c $< -o $@

test: $(TEST_EXECUTABLE)

$(TEST_EXECUTABLE): $(TEST_OBJS)
	$(CC) $(CFLAGS) $(TEST_OBJS) -o $(TEST_EXECUTABLE) $(LIBS)

.cpp.o:
	$(CC) $(CFLAGS) -c $< -o $@

clean:
	rm -f $(OBJS) $(EXECUTABLE) $(TEST_OBJS) $(TEST_EXECUTABLE)

