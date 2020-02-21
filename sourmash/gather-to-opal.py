#! /usr/bin/env python3
"""
Take a gather CSV and one or more NCBI 'accession2taxid' files
and create 1) csv containing accessions, taxid, and 2) csv with linage, %
run:
python gather-to-opal.py example_output.csv --acc2taxid_files nucl_gb.accession2taxid.gz nucl_wgs.accession2taxid.gz
"""

from __future__ import print_function
import re
import os
import gzip
import argparse
import pandas as pd

import taxonomy


def get_taxid(gather_csv, acc2taxid_files):

    gather_info = pd.read_csv(gather_csv)
    # grab the acc from gather column `name`
    gather_info["accession"] = gather_info["name"].str.replace("\..*", "")
    gather_info["percentage"] = gather_info["f_unique_weighted"] * 100
    m = 0
    # init opal_info df
    opal_info = gather_info.loc[:, ["accession", "percentage"]].copy()
    opal_info.set_index("accession", inplace=True)
    acc_set = set(opal_info.index)

    for filename in acc2taxid_files:
        if not acc_set:
            break

        xopen = open
        if filename.endswith(".gz"):
            xopen = gzip.open

        with xopen(filename, "rt") as fp:  # ruun through acc2taxid files
            next(fp)  #  skip headers
            for n, line in enumerate(fp):
                if not acc_set:
                    break

                if n and n % 1000000 == 0:
                    print("\r\033[K", end="")
                    print(
                        "... read {} lines of {}; found {} of {}".format(
                            n, filename, m, m + len(acc_set)
                        ),
                        end="\r",
                    )

                try:
                    acc, acc_version, taxid, _ = [l.strip() for l in line.split()]
                except ValueError:
                    print("ignoring line", (line,))
                    continue

                if acc in acc_set:

                    m += 1
                    opal_info.loc[acc, "taxid"] = str(taxid)
                    acc_set.remove(acc)

                    if not acc_set:
                        break
    if acc_set:
        print("failed to find {} acc: {}".format(len(acc_set), acc_set))
    else:
        print("found all {} accessions!".format(m))

    return opal_info


def get_row_taxpath(row, taxo, ranks):
    # uses taxonomy pkg
    lineage = taxo.lineage(str(int(row["taxid"])))
    valid_ranks = {}
    for l in lineage:
        current_rank = taxo.rank(l)
        if current_rank in ranks:
            valid_ranks[current_rank] = l

    final_lineage = []
    for rank in ranks:
        if rank in valid_ranks:
            final_lineage.append(valid_ranks[rank])
        else:
            final_lineage.append("")

    row["rank"] = "species"
    row["taxpath"] = "|".join(final_lineage)
    return row


def summarize_all_levels(df, ranks):
    new_rows = []
    for (percentage, tax_id, rank, taxpath) in df.itertuples(index=False, name=None):
        new_rows.append([percentage, int(tax_id), rank, taxpath])

        lineage_values = taxpath.split("|")
        for i, (rank, tax_id) in enumerate(zip(ranks, lineage_values), 1):
            if not tax_id:
                continue

            taxpath = "|".join(lineage_values[:i])
            new_rows.append([percentage, tax_id, rank, taxpath])

    new_df = pd.DataFrame(new_rows, columns=df.columns)
    return new_df.groupby(["taxid", "rank", "taxpath"], as_index=False).sum()


def gen_report(sample_id, ranks, taxonomy_id, program, taxons):
    output = f"""# Taxonomic Profiling Output
@SampleID:{sample_id}
@Version:0.10.0
@Ranks:{ranks}
@TaxonomyID:{taxonomy_id}
@__program__:{program}
@@TAXID\tRANK\tTAXPATH\tPERCENTAGE
"""
    all_taxons = []
    for tax in taxons.itertuples(index=False, name=None):
        tax_line = "\t".join(str(t) for t in tax)
        all_taxons.append(tax_line)

    out = output + "\n".join(all_taxons)
    return out + "\n"


def main(
    gather_csv, acc2taxid_files, taxdump, tax_ranks, *, opal_csv=None, taxid_csv=None
):
    if not taxid_csv:
        opal_info = get_taxid(gather_csv, acc2taxid_files)
        taxid_csv = gather_csv.rsplit(".csv")[0] + "_taxid.csv"
        opal_info.to_csv(taxid_csv)
    else:
        opal_info = pd.read_csv(taxid_csv, index_col=0)

    # Drop tax_ids not found. There is a warning already on the `get_taxid`
    # function, but might want to be more eloquent...
    opal_info.dropna(subset=["taxid"], inplace=True)

    # load ncbi taxonomy info
    taxo = taxonomy.Taxonomy.from_ncbi(
        os.path.join(taxdump, "nodes.dmp"), os.path.join(taxdump, "names.dmp")
    )

    # get lineage using taxid
    tax_df = opal_info.apply(lambda row: get_row_taxpath(row, taxo, tax_ranks), axis=1)

    # summarize taxonomic ranks
    rank_df = summarize_all_levels(tax_df, tax_ranks)
    if not opal_csv:
        opal_csv = gather_csv.rsplit(".csv")[0] + "_opal.csv"

    sample_id = "test"
    taxonomy_id = "taxonomy_id"
    program = "sourmash gather"
    out = gen_report(sample_id, "|".join(tax_ranks), taxonomy_id, program, rank_df)
    with open(opal_csv, "w") as f:
        f.write(out)


if __name__ == "__main__":
    p = argparse.ArgumentParser()
    p.add_argument("gather_csv")
    p.add_argument("--acc2taxid_files", action="append")
    p.add_argument("--taxdump_path", default="taxdump")
    p.add_argument(
        "--ranks", default="superkingdom|phylum|class|order|family|genus|species"
    )
    p.add_argument("--taxid_csv")  # testing, default="example_output_taxid.csv")
    p.add_argument("--opal_csv")
    args = p.parse_args()
    main(
        args.gather_csv,
        args.acc2taxid_files,
        args.taxdump_path,
        args.ranks.split("|"),
        opal_csv=args.opal_csv,
        taxid_csv=args.taxid_csv,
    )
