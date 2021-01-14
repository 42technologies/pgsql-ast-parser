@lexer lexerAny
@include "base.ne"

array_of[EXP] -> $EXP (%comma $EXP {% last %}):* {% ([head, tail]) => {
    return [unwrap(head), ...(tail.map(unwrap) || [])];
} %}


# https://www.postgresql.org/docs/current/sql-createview.html
create_view_statements -> create_view | create_materialized_view


create_view -> %kw_create
                (%kw_or kw_replace):?
                (kw_temp | kw_temporary):?
                kw_recursive:?
                kw_view
                qualified_name
                (lparen array_of[ident] rparen {% get(1) %}):?
                create_view_opts:?
                %kw_as
                select_statement
                (%kw_with (kw_local | kw_cascaded) %kw_check kw_option {% get(1) %}):? {% x => {
                    return {
                        type: 'create view',
                        ... x[1] && {orReplace: true},
                        ... x[2] && {temp: true},
                        ... x[3] && {recursive: true},
                        ... x[5], // name
                        ... x[6] && {columnNames: x[6]},
                        ... x[7] && {parameters: Object.fromEntries(x[7])},
                        query: x[9],
                        ... x[10] && { checkOption: toStr(x[10]) },
                    }
                } %}




create_view_opt -> ident %op_eq ident {% ([a, _, b]) => [toStr(a), toStr(b)] %}

create_view_opts -> %kw_with array_of[create_view_opt] {% last %}


# https://www.postgresql.org/docs/current/sql-creatematerializedview.html

create_materialized_view -> %kw_create
                kw_materialized
                kw_view
                kw_ifnotexists:?
                qualified_name
                (lparen array_of[ident] rparen {% get(1) %}):?
                create_view_opts:?
                (kw_tablespace ident {% last %}):?
                %kw_as
                select_statement
                (%kw_with kw_no:? kw_data):? {% x => {
                    return {
                        type: 'create materialized view',
                        ... x[3] && {ifNotExists: true},
                        ... x[4], // name
                        ... x[5] && {columnNames: x[6]},
                        ... x[6] && {parameters: Object.fromEntries(x[6])},
                        ... x[7] && {tablespace: toStr(x[7]) },
                        query: x[9],
                        ... x[10] && { withData: toStr(x[10][1]) !== 'no' },
                    }
                } %}