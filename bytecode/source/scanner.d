module scanner;

// Scanner being globaly defined is for easiness of the book
Scanner scanner;

struct Scanner
{
	immutable(char)* start;
	immutable(char)* current;
	size_t line;
}

void initScanner(const string source)
{
	scanner.start = &source[0];
	scanner.current = &source[0];
	scanner.line = 1;
}
