🏃‍♀️ `pg-sql-parser` is a Postgres SQL syntax parser. It produces a typed AST tree, covering the most common syntaxes of pgsql.

**⚠** This parser does not support (yet) PL/pgSQL. It might not even cover some funky syntaxes.

💓 Open an issue if you find an bug or unsupported syntax !

🔗 This parser has been created to implement [pg-mem](https://github.com/oguimbal/pg-mem), an in-memory postgres db emulator. 👉 [Play with it here](https://oguimbal.github.io/pg-mem-playground/)


# 📐 Installation

## With NodeJS

```bash
npm i pg-sql-parser
```

## With Deno

Just reference it like that:

```typescript
import { /* imports here */ } from 'https://deno.land/x/pg_sql_parser/mod.ts';
```

# 📖 Parsing SQL

⚠ I strongly recommand NOT using this parser without Typescript. It will work, but types are awesome.

Parse sql to an AST (Abstract Syntax Tree) like this:

```typescript
import { parse, Statement } from 'pg-sql-parser;

// parse multiple statements
const ast: Statement[] = parse(`BEGIN TRANSACTION;
                                insert into my_table values (1, 'two')`);

// parse a single statement
const ast: Statement = parseFirst(`SELECT * FROM "my_table";`);
```


# 🔍 Inspecting SQL AST

Once you have parsed an AST, you might want to traverse it easily to know what's in it.

There is a helper for that: `astVisitor`.

Here is an example

```typescript

import { astVisitor, parse } from 'pg-sql-parser';

const tables = new Set();
let joins = 0;
const visitor = astVisitor(map => ({

    // implement here AST parts you want to hook

    tableRef: t => tables.add(t.table),
    join: t => {
        joins++;
        // call the default implementation of 'join'
        // this will ensure that the subtree is also traversed.
        map.super().join(t);
    }
}))

// start traversing a statement
visitor.statement(parseFirst(`select * from ta left join tb on ta.id=tb.id`));

// print result
console.log(`Used tables ${[...tables].join(', ')} with ${joins} joins !`)

```

You'll find that AST visitors (that's the name of this pattern) are quite flexible and powerful once you get used to them !

👉 Here is the implementation of [toSql](./src/to-sql.ts) which uses an astVisitor to reconstitude SQL from an AST (see below).



# 🖨 Converting an AST to SQL

That's super easy:

```typescript
import { toSql } from 'pg-sql-parser';

const sql: string = toSql.statement(myAst);

```

ℹ Like with visitor, you can also convert subparts of AST to SQL (not necessarily a whole statement) by calling other methods of toSql.


# 📝 Modifying SQL AST


There is a special kind of visitor, which I called `astMapper`, which allows you to traverse & modify ASTs on the fly.

For instance, you could rename a table in a request like this:

```typescript
import { toSql, parseFirst, astMapper } from 'pg-sql-parser';

// create a mapper
const mapper = astMapper(map => ({
    tableRef: t => {
        if (t.table === 'foo') {
            return {
                 // Dont do that... see below
                 // (I wrote this like that for the sake of explainability)
                ...t,
                table: 'bar',
            }
        }

        // call the default implementation of 'tableRef'
        // this will ensure that the subtree is also traversed.
        return map.super().tableRef(t);
    }
}))

// parse + map + reconvert to sql
const modified = mapper.statement(parseFirst('select * from foo'));

console.log(toSql.statement(modified!)); //  =>  SELECT * FROM "bar"

```


## A note on `astMapper` performance:

The AST default modifier tries to be as efficient as possible:
It does not copy AST parts as long as they do not have changed.

If you wan to avoid unnecessary copies, try to return the original argument
as much as possible when nothing has changed.

For instance, instead of writing this:

```typescript
    member(val: a.ExprMember) {
        const operand = someOperandTransformation(val.operand);
        if (!operand) {
            return null;
        }
        return {
            ...val,
            operand,
        }
    }
```

Prefer an implement that checks that nothing has changed, for instance by using the `assignChanged()` helper.

```typescript
    member(val: a.ExprMember) {
        const operand = someOperandTransformation(val.operand);
        if (!operand) {
            return null;
        }
        return assignChanged(val, {
            operand,
        });
    }
```

It's pretty easy to implement.
To deal with this kind optimization with arrays, there is a `arrayNilMap()` helper exposed:

```typescript
const newArray = arrayNilMap(array, elem => transform(elem));
if (newArray === array) {
    // transform() has not changed any element in the array !
}
```
