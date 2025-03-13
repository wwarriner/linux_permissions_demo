import pandas as pd


def get_permissions(x):
    # converts a path to a
    d, s, f = x.partition("/")
    if s == "":
        # file
        return ("", "")


def key(x):
    return (x[0], "/".join(reversed(x[1].split("/"))))


def insert_info_row(df: pd.DataFrame, position: int, index: str) -> pd.DataFrame:
    new_df = pd.DataFrame(index=[index], columns=df.columns)
    before = df.iloc[:position]
    after = df.iloc[position:]
    return pd.concat([before, new_df, after])


def b(s: str) -> str:
    return f"**{s}**"


ORDER = [
    # file-only operations
    "cat",
    "append redirect (>>)",
    "clobber redirect (>)",
    "execute",
    # both operations
    "cp",
    "find",
    "ls",
    "ls -l",
    "mv",
    "rm",
    "rm -f",
    # dir-only operations
    "cd",
    "cp -r",
    "cp file into dir",
    "mv file into dir",
    "rm -r",
    "rm -rf",
]


if __name__ == "__main__":
    df = pd.read_csv(
        "results.csv",
        header=None,
        names=["command", "type", "directory permissions", "file permissions", "code"],
    )
    df["file permissions"] = df["file permissions"].fillna("")

    # df[
    #     df.duplicated(
    #         ["command", "type", "directory permissions", "file permissions"], keep=False
    #     )
    # ].to_csv("dupes.csv")

    p = df.pivot(
        index="command",
        columns=["type", "directory permissions", "file permissions"],
        values="code",
    )
    p = p.reindex(sorted(p.columns, key=key), axis="columns")
    p = p.reindex(ORDER, axis="index")
    p = p.rename(lambda x: f"{x} ⸸" if x.startswith("rm") else x, axis="index")

    p[p > 0] = 1
    p[p.isna()] = -1
    p = p.astype(int)
    p = p.astype(str)
    p = p.replace("-1", "")
    # p = p.replace("0", "✔️")
    p = p.replace("0", "X")
    # p = p.replace("1", "❌")
    p = p.replace("1", "")

    p = insert_info_row(p, 11, b("Directory Operations"))
    p = insert_info_row(p, 4, b("Operations for Both"))
    p = insert_info_row(p, 0, b("File Operations"))

    p.to_csv("table.csv")
