#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "common.h"

extern struct sql_statement_t sql_statement;

int get_statement(FILE *query_input)
{
	char line[128];
	char *pos_begin;
	int comment_index, statement_index;

	sql_statement.statement[0]='\0';
	sql_statement.comment[0]='\0';
	comment_index=0;
	statement_index=0;

	while (fgets(line, 127, query_input) != NULL)
	{
		/* skip the blank lines */
		if (line[0] == '\n')
			continue;

		/* remove the leading spaces */
		ltrim(line);

		/* if this is a comment line, store it to statement.comment */
		if (line[0]=='-' && line[1]=='-') 
		{
			comment_index += sprintf(sql_statement.comment+comment_index, "%s", line);
			/* get query number */
			if ((pos_begin=strstr(line, "Query (")) != NULL)
			{
				pos_begin+=strlen("Query (Q");
				sql_statement.query_id = atoi(pos_begin);
			}
		}
		/* if this is a 'set row' line, store the row count */
		else if (strncmp(line, "set rowcount", 12) == 0)
		{
			pos_begin=line+13;
			sql_statement.rowcount=atoi(pos_begin);
		}
		/* if it is "go", then this is the end of this block */
		else if (strcmp(line,"go\n") == 0)
			return END_OF_BLOCK;
		/* otherwise, it is sql statement */
		else
		{
			if ( (pos_begin=strchr(line, ';')) != NULL)
			{
#ifdef sapdb
				/* if it is the end of the statement, add \n */
				*pos_begin='\n';
				statement_index += sprintf(sql_statement.statement+statement_index, "%s", line);
#endif
#ifdef pgsql
				/* pgsql requires ';' */
				statement_index += sprintf(sql_statement.statement+statement_index, "%s", line);
				statement_index += sprintf(sql_statement.statement+statement_index, "%c", '\n');
#endif
				return END_OF_STMT;
			}
			/* get rid of \n */
			else if ( (pos_begin=strchr(line, '\n')) != NULL)
			{
				*pos_begin=' ';
				statement_index += sprintf(sql_statement.statement+statement_index, "%s", line);
			}
		}
	}
	return END_OF_FILE;
}

void ltrim(char *str)
{
	char *start_pos;

	start_pos=str;
	while (*start_pos == ' ' || *start_pos == '\t') start_pos++;
	strcpy(str, start_pos);
}