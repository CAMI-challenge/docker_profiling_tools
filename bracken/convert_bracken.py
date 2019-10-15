#!/usr/bin/env python3
import load_ncbi_taxinfo
import sys
import os
from collections import defaultdict
from collections import OrderedDict


def open_bracken_file(file, tax_id_to_parent, tax_id_to_rank):
    taxid_to_score = {}
    with open(file) as f:
        next(f)
        for line in f:
            line_split = line.rstrip().split('\t')
            tax_id = line_split[1]
            if tax_id not in tax_id_to_parent or tax_id_to_rank[tax_id] != 'species':
                continue
            score = float(line_split[6])
            taxid_to_score[tax_id] = score
    return taxid_to_score


def convert(file, tax_id_to_parent, tax_id_to_rank, tax_id_to_name):
    tax_id_to_score = open_bracken_file(file, tax_id_to_parent, tax_id_to_rank)

    rank_to_tax_id_to_score = defaultdict(dict)
    rank_to_tax_id_to_id_path = defaultdict(dict)

    species_index = load_ncbi_taxinfo.DICT_RANK_TO_INDEX['species']
    for tax_id in tax_id_to_score.keys():
        rank_to_tax_id_to_score[species_index][tax_id] = tax_id_to_score[tax_id]
        rank_to_tax_id_to_id_path[species_index][tax_id] = load_ncbi_taxinfo.get_id_path(tax_id, tax_id_to_parent, tax_id_to_rank)

    for rank in load_ncbi_taxinfo.RANKS[:-2]:
        rank_index = load_ncbi_taxinfo.DICT_RANK_TO_INDEX[rank]
        tax_id_to_id_path_sorted = OrderedDict(sorted(rank_to_tax_id_to_id_path[species_index].items(), key=lambda t: rank_to_tax_id_to_id_path[species_index][t[0]][rank_index]))

        tax_id2 = None
        for tax_id in tax_id_to_id_path_sorted:
            tax_id_r = tax_id_to_id_path_sorted[tax_id][rank_index]
            if tax_id_r == '':
                tax_id2 = None
                continue
            if tax_id_r == tax_id2:
                rank_to_tax_id_to_score[rank_index][tax_id_r] += rank_to_tax_id_to_score[species_index][tax_id]
            else:
                rank_to_tax_id_to_score[rank_index][tax_id_r] = rank_to_tax_id_to_score[species_index][tax_id]
                rank_to_tax_id_to_id_path[rank_index][tax_id_r] = rank_to_tax_id_to_id_path[species_index][tax_id][:rank_index + 1]
            tax_id2 = tax_id_r

    sample_id = "sampleid"
    with open(file.rstrip(".orig") + ".profile", "w") as f:
        f.write("@SampleID:{}\n@Version:0.9.1\n@Ranks:superkingdom|phylum|class|order|family|genus|species|strain\n\n@@TAXID\tRANK\tTAXPATH\tTAXPATHSN\tPERCENTAGE\n".format(sample_id))
        for rank in load_ncbi_taxinfo.RANKS:
            rank_index = load_ncbi_taxinfo.DICT_RANK_TO_INDEX[rank]
            for tax_id in rank_to_tax_id_to_score[rank_index]:
                if rank_to_tax_id_to_score[rank_index][tax_id] == .0:
                    continue
                id_path = rank_to_tax_id_to_id_path[rank_index][tax_id]
                name_path = []
                for id in id_path:
                    name_path.append(tax_id_to_name[id])
                f.write("{}\t{}\t{}\t{}\t{}\n".format(tax_id, tax_id_to_rank[tax_id], "|".join(id_path), "|".join(name_path), rank_to_tax_id_to_score[rank_index][tax_id] * 100))


def main():
    tax_id_to_parent, tax_id_to_rank = load_ncbi_taxinfo.load_tax_info(os.environ['PREFIX'] + '/share/taxonomy/nodes.dmp')
    tax_id_to_name = load_ncbi_taxinfo.load_names(tax_id_to_rank, os.environ['PREFIX'] + '/share/taxonomy/names.dmp')
    convert(sys.argv[1], tax_id_to_parent, tax_id_to_rank, tax_id_to_name)


if __name__ == "__main__":
    main()

