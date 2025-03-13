# Linux Permissions Demo

Want to better understand Linux permissions? This is a tool that produces a
table of common commands, and whether they succeed or fail depending on the
permissions of the file and its containing directory.

## How To Use

1. Setup the conda enviroment in `environment.yml`.
2. Run `permissions.sh && python tabulate.py`.
3. Review the generated file `table.csv`.

## Notes

- Files
  - `r`: file contents can be read or streamed out (`cp`)
  - `w`: file contents can be modified or streamed in
  - `x`: compiled binary can be executed
  - `rx`: script can be executed (`r` is required because the script must be read by the interpreter)
- Directory
  - `r`: directory contents can be listed
  - `wx`: directory contents can be modified and directory can be traversed
  - `x`: directory can be traversed
  - `s`: directory can be traversed and all newly created subdirectories will inherit the group owner of this directory. In almost all cases you will want to use `s` in place of `x` in shared directories.
  - NOTE: `w` without `x` allows no additional permissions. It's just the way the Linux Kernel is structured.

- Useful tools for data managers in shared allocations.
  - Recommended default permissions for files `u=rwx,g=rwx,o=---` or `770`
  - Read-only files? File `u=rwx,g=r--,o=---` or `740`
  - Recommended default permissions for directories `u=rwx,g=rws,o=---` or `2770`
  - View-only directories, or outbox directories? Directory `u=rwx,g=r-s,o=---` or `2750`
  - Inbox directory with hidden contents? Directory `u=rwx,g=-ws,o=---` or `2730`

Note: `x` and `s` are interchangeable for directories below here.

- Commands
  - File:
    - `cat` requires directory `x` and file `r`. This applies to any attempts to view file contents.
    - `cp` requires file `r`, source directory `x`, and destination directory `wx`.
    - `>` and `>>` to a file requires directory `x` and file `w`. This applies to any attempts to modify file contents.
    - Executing a file requires directory `x` and file `x`.
    - `rm` requires directory `wx`.
    - `touch` requires directory `wx`.
  - Directory:
    - `cd` requires `x`.
    - `cp -r` requires file `r`, source directory `rx` and destination directory `wx`. All source files, recursively, must have `r`. All source subdirectories, recursively, must have `rx`. File permissions do not matter.
    - `mv` requires source directory `wx` and destination directory `wx`. File permissions do not matter.
    - `rm -r` requires `rwx`. All subdirectories, recursively, must have `rwx`. File permissions do not matter.
  - Either:
    - `ls` requires directory `x`.
    - `ls -l` requires directory `rx`.

- Things you might want to do and the minimal and preferred permissions required.
  - Read the contents of a file? File `r` and directory `x`.
  - Modify the contents of a file? File `w` and directory `x`. Preferred: In most cases you will want to read what you are modifying, which is `rw`.
  - Execute a binary? Minimal: file `x`, directory `x`. Preferred: Same. Binaries don't need to be read and should not be modified once compiled.
  - Execute a script? File `rx` and directory `x`.
  - Traverse a directory to a subdirectory? Directory `x`. Having only `x` on a directory is useful for restricting access to intermediate directories in combination with ACLs.
  - List contents of a directory? Minimal: Directory `r`. Preferred: In most cases you will also want to traverse the directory, which is `rx`. Note that just `r` will result in a partial error for each file and subdirectory, and extended metadata will not be available.
  - Delete contents of a directory? Directory `wx`.
  - Copy or move into a directory? Directory `wx`.
  - Rename contents of a directory? Directory `wx`.
  - New subdirectories should inherit group owner? Directory `s` instead of merely `x`. Use `g+s` or append a leading `2` to the mode bits, e.g. `2770`.

We can use an analogy to better  permissions, imagine a directory full of files as a basket full of books.

- To see the titles of the books in the basket, you need read permission on the basket. `ls basket`.
- To
- To see the author and copyright date of books in the basket, you need read and execute permission on the basket. `ls -l basket`.
- To read the books, you need read permission on each book. `cat basket/book`.
- To write in the books, tear out pages, or remove all of the ink, you need write permission on each book. `"replace" > basket/book`, `"append" >> basket/book`.
- To use a book for studying (reading and making margin notes), you need both read and write permission. `nano book`.
- To create a blank book, you need write and execute permission on the basket. `touch basket/book`.
- To destroy a book, you need write and execute permission on the basket. `rm basket/book`.
- If you have a tablet in the basket, you can use (execute) it to read books to you. `basket/tablet-read basket/book`.

If you have a second basket...

- To copy a book to the second basket, you need read permission on the first basket and write and execute permission on the second. This is because you need to be able to read the book to copy it to a new basket.
- To move a book to the second basket, you need execute permission on the first basket and write and execute permission on the second. This is because you need to be able to change the contents of both baskets, and write to the second. Note that you don't need to read the contents of the book to move it! You can just pick it up and put it back down.
