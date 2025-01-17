@lexer lexerAny
@include "base.ne"


# https://www.postgresql.org/docs/12/sql-createindex.html
createindex_statement
    -> %kw_create
        %kw_unique:?
        kw_index
        kw_ifnotexists:?
        word:?
        %kw_on
        table_ref
        (%kw_using ident {% last %}):?
        lparen
        createindex_expressions
        rparen
        createindex_predicate:?
         {% x => track(x, {
            type: 'create index',
            ...x[1] && { unique: true },
            ...x[3] && { ifNotExists: true },
            ...x[4] && { indexName: asName(x[4]) },
            table: x[6],
            ...x[7] && { using: asName(x[7]) },
            expressions: x[9],
            ...x[11] && { where: unwrap(x[11]) },
        }) %}

createindex_expressions -> createindex_expression (comma createindex_expression {% last %}):* {% ([head, tail]) => {
    return [head, ...(tail || [])];
} %}

createindex_expression -> (expr_basic | expr_paren)
        (%kw_collate qualified_name {% last %}):?
        qualified_name:?
        (%kw_asc | %kw_desc):?
        (kw_nulls (kw_first | kw_last) {% last %}):? {% x => track(x, {
    expression: unwrap(x[0]),
    ...x[1] && { collate: unwrap(x[1]) },
    ...x[2] && { opclass: unwrap(x[2]) },
    ...x[3] && { order: unwrap(x[3]).value },
    ...x[4] && { nulls: unwrap(x[4]) },
}) %}


createindex_predicate -> %kw_where expr {% last %}
