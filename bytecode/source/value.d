module value;

alias Value = double;
alias ValueArray = Value[];

void initValueArray(ref scope ValueArray values)
{
	values = [];
}

alias freeValueArray = initValueArray;

void writeValueArray(ref scope ValueArray values, Value value)
{
	values ~= value;
}
