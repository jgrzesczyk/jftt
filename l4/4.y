%{
#include <iostream>
#include <fstream>
#include <cstdlib>
#include <string>
#include <sstream>
#include <cmath>
#include <vector>
#include <map>

typedef struct {
	std::string name;
    std::string type; //NUM, IDE, ARR
    bool initialized;
    int counter;
	long long int mem;
	bool local;
	bool isTable;
  	long long int beginTable;
	long long int endTable;
} Identifier;

typedef struct {
    long long int placeInStack;
    long long int depth;
} Jump;

std::vector<std::string> codeStack;
std::map<std::string, Identifier> idStack;

int yyerror (const std::string);
extern int yylineno;
extern FILE * yyin;
int yylex();


void setRegister(std::string);
void zeroRegister();
void createIdentifier(Identifier* id, std::string name, bool isLocal, std::string type);
void createIdentifier(Identifier* id, std::string name, bool isLocal, std::string type, long long int begin, long long int end);
void insertIdentifier(std::string key, Identifier i);
void pushCommand(std::string);
void pushCommand(std::string, long long int);
void memToRegister(long long int);
std::string decToBin(long long int n);
void registerToMem(long long int);
long long int memCounter;
long long int depth;
bool assignFlag;
bool writeFlag;
Identifier assignTarget;
std::string tabAssignTargetIndex = "-1";
std::string expressionArguments[2] = {"-1", "-1"};
std::string argumentsTabIndex[2] = {"-1", "-1"};
%}

%define parse.error verbose
%define parse.lac full

%union {
	char* str;
	long long int num;
}
%start program

%token <str> NUM IDENT
%token <str> DECLARE IN END READ WRITE FOR FROM TO DOWNTO DO WHILE IF THEN ELSE ENDFOR ENDWHILE ENDIF ENDDO
%token <str> ASSIGN NEQ EQ LE GE GT LT INDEXER COLON ADD SUB MUL DIV MOD LB RB

%type <str> value
%type <str> identifier
%%

program: DECLARE declarations IN commands END {
	pushCommand("HALT");
}
;

declarations: 
| declarations IDENT COLON {
	if(idStack.find($2) != idStack.end()) {
		std::cout << "Błąd [okolice linii " << yylineno << "]: Kolejna deklaracja zmiennej " << $<str>2 << std::endl;
		exit(1);
	} else {
		Identifier ide;
		createIdentifier(&ide, $2, false, "IDE");
		insertIdentifier($2, ide);
	}
}
| declarations IDENT LB NUM INDEXER NUM RB COLON {
	if(idStack.find($2) != idStack.end()) {
		std::cout << "Błąd [okolice linii " << yylineno << "]: Kolejna deklaracja zmiennej " << $<str>2 << std::endl;
		exit(1);
	} else if (atoll($4) > atoll($6)) {
        std::cout << "Błąd [okolice linii " << yylineno << "]: Indeksy tablicy " << $<str>2 << " są niepoprawne" << std::endl;
		exit(1);
    } else if (atoll($4) < 0) {
        std::cout << "Błąd [okolice linii " << yylineno << "]: Początek tablicy o indeksie " << $<str>2 << " < 0!" << std::endl;
		exit(1);
    } else {
		Identifier ide;
		createIdentifier(&ide, $2, false, "IDE", atoll($4), atoll($6));
		insertIdentifier($2, ide);
		memCounter = memCounter + (atoll($6) - atoll($4) + 1);
		setRegister(std::to_string(ide.mem+1));
        registerToMem(ide.mem);
	}
}
;

commands: commands command
| command
;

command: identifier ASSIGN expression COLON {
	
}
| IF condition THEN commands ifbody {
	
}
| WHILE condition DO commands ENDWHILE {
	
}
| DO commands WHILE condition ENDDO {
	
}
| FOR IDENT FROM value forbody {
	
}
| READ identifier COLON {
	
}
| WRITE value COLON {
	
}
;

ifbody: ELSE commands ENDIF {

}
| ENDIF {

}
;

forbody: TO value DO commands ENDFOR {

}
| DOWNTO value DO commands ENDFOR {

}
;

expression: value {
	
}
| value ADD value {
	
}
| value SUB value {
	
}
| value MUL value {
	
}
| value DIV value {
	
}
| value MOD value {
	
}
;

condition: value EQ value {
	
}
| value NEQ value {
	
}
| value LT value {
	
}
| value GT value {
	
}
| value LE value {
	
}
| value GE value {
	
}
;

value: NUM {
	
}
| identifier {
	
}
;

identifier: IDENT {
	if(idStack.find($1) == idStack.end()) {
		std::cout << "Błąd [okolice linii " << yylineno << "]: Niezadeklarowana zmienna " << $<str>1 << std::endl;
		exit(1);
	} 
	if(!idStack.at($1).isTable) {
		if(!assignFlag) {
			if(!idStack.at($1).initialized) {
				std::cout << "Błąd [okolice linii " << yylineno << "]: Użyta niezainicjowana zmienna " << $<str>1 << std::endl;
				exit(1);
			}
			if (expressionArguments[0] == "-1"){
                    expressionArguments[0] = $1;
                }
                else{
                    expressionArguments[1] = $1;
                }
		}
	} else {
		std::cout << "Błąd [okolice linii " << yylineno << "]: Przypisanie wartości do całej tablicy " << $<str>1 << std::endl;
		exit(1);
	}
}
| IDENT LB IDENT RB {
	if(idStack.find($1) == idStack.end()) {
		std::cout << "Błąd [okolice linii " << yylineno << "]: Niezadeklarowana zmienna " << $<str>1 << std::endl;
		exit(1);
	} 
	if(idStack.find($3) == idStack.end()) {
		std::cout << "Błąd [okolice linii " << yylineno << "]: Niezadeklarowana zmienna " << $<str>3 << std::endl;
		exit(1);
	} 

	if(!idStack.at($1).isTable) {
		std::cout << "Błąd [okolice linii " << yylineno << "]: Zmienna " << $<str>1 << " nie jest tablicą!" << std::endl;
		exit(1);
	} else {
		if(!idStack.at($3).initialized) {
			std::cout << "Błąd [okolice linii " << yylineno << "]: Użyta zmienna " << $<str>3 << " nie jest zainicjowana!" << std::endl;
			exit(1);
		}
	

	}
}
| IDENT LB NUM RB {
	if(idStack.find($1) == idStack.end()) {
		std::cout << "Błąd [okolice linii " << yylineno << "]: Niezadeklarowana zmienna " << $<str>1 << std::endl;
		exit(1);
	}
	if(!idStack.at($1).isTable) {
		std::cout << "Błąd [okolice linii " << yylineno << "]: Zmienna " << $<str>1 << " nie jest tablicą!" << std::endl;
		exit(1);
	} else {
		if(!(idStack.at($1).beginTable <= atoll($3) && idStack.at($1).endTable >= atoll($3))) {
			std::cout << "Błąd [okolice linii " << yylineno << "]: Odwołanie do złego indeksu tablicy " << $<str>1 << "!" << std::endl;
			exit(1);
		}
	

	}

}
;
%% 

void setRegister(std::string number) {
    long long int n = stoll(number);
	/*if (n == registerValue) {
		return;
	}*/
    std::string bin = decToBin(n);
	long long int limit = bin.size();
    zeroRegister();
	for(long long int i = 0; i < limit; ++i){
		if(bin[i] == '1'){
			pushCommand("INC");
			/*registerValue++;*/
		}
		if(i < (limit - 1)){
	        pushCommand("SHL");
	        /*registerValue *= 2;*/
		}
	}
}

void memToRegister(long long int mem) {
	pushCommand("LOAD", mem);
	/*registerValue = -1;*/
}

std::string decToBin(long long int n) {
    std::string r;
    while(n!=0) {r=(n%2==0 ?"0":"1")+r; n/=2;}
    return r;
}

void registerToMem(long long int mem) {
	pushCommand("STORE", mem);
}

void createIdentifier(Identifier* id, std::string name, bool isLocal, std::string type) {
	id->name = name;
	id->mem = memCounter;
	id->type = type;
	id->initialized = false;
	id->local = isLocal;
	id->isTable = false;
	id->beginTable = -1;
	id->endTable = -1;
}
void createIdentifier(Identifier* id, std::string name, bool isLocal, std::string type, long long int begin, long long int end) {
	id->name = name;
	id->mem = memCounter;
	id->type = type;
	id->initialized = false;
	id->local = isLocal;
	id->isTable = true;
	id->beginTable = begin;
	id->endTable = end;
}
void insertIdentifier(std::string key, Identifier i) {
    if(idStack.count(key) == 0) {
        idStack.insert(make_pair(key, i));
        idStack.at(key).counter = 0;
        memCounter++;
    }
    else {
        idStack.at(key).counter = idStack.at(key).counter+1;
    }
    std::cout << "Add: " << key << " " << memCounter-1 << std::endl;
}

void pushCommand(std::string str) {
    codeStack.push_back(str);
}

void pushCommand(std::string str, long long int num) {
    std::string temp = str + " " + std::to_string(num);
    codeStack.push_back(temp);
}

void printStdCode() {
	long long int i;
	for(i = 0; i < codeStack.size(); i++)
        std::cout << codeStack.at(i) << std::endl;
}

void printCode(std::string filename) {
	std::ofstream out_code(filename);
	long long int i;
	for(i = 0; i < codeStack.size(); i++)
        out_code << codeStack.at(i) << std::endl;
}

int main (int argc, char** argv) {
	assignFlag = true;
	memCounter = 12;
	writeFlag = false;
	depth = 0;

	yyin = fopen(argv[1], "r");
    yyparse();

	if(argc < 3) {
		//todo printStdCode();
	} else {
		printCode(argv[2]);
	}
	return 0;
}

int yyerror(const std::string s) {
	std::cout << "Błąd [około linii " << yylineno << "]: " << s << std::endl;
	exit(1);
}