# -*- coding: utf-8 -*-
"""ORF_Finder_Laurival.ipynb
Automatically generated by Colaboratory.
Original file is located at
    https://colab.research.google.com/drive/1lz15943_X__5oW9qo47fj5UQ5GPHn8Io
FASTA
"""

import io
import csv
import sys
from io import StringIO
import pandas as pd
from collections import Counter

def read_fasta(fasta_file):
  arq_leitura = open(fasta_file, "r")
  header, sequence = '', []

  for line in arq_leitura:
    if line[0] == '>':
      if sequence:
        yield {"id": header, "seq": "".join(sequence)}
      header = line[1:-1]
      sequence = []
    else:
      sequence.append(line.strip())
  yield {"id": header, "seq": "".join(sequence)}

# get complement from seq
def complement(seq):
  r = ""
  comp = {"A":"T", "T":"A", "C":"G", "G":"C"}
  for i in seq:
    r += comp[i]
  return r

def reversed_complement(seq):
  return complement(seq[::-1])

#print(complement("ACGT"))
#print(reversed_complement("ACGT"))

def translate(seq):

  table = {
    'ATA':'I', 'ATC':'I', 'ATT':'I', 'ATG':'M',
    'ACA':'T', 'ACC':'T', 'ACG':'T', 'ACT':'T',
    'AAC':'N', 'AAT':'N', 'AAA':'K', 'AAG':'K',
    'AGC':'S', 'AGT':'S', 'AGA':'R', 'AGG':'R',
    'CTA':'L', 'CTC':'L', 'CTG':'L', 'CTT':'L',
    'CCA':'P', 'CCC':'P', 'CCG':'P', 'CCT':'P',
    'CAC':'H', 'CAT':'H', 'CAA':'Q', 'CAG':'Q',
    'CGA':'R', 'CGC':'R', 'CGG':'R', 'CGT':'R',
    'GTA':'V', 'GTC':'V', 'GTG':'V', 'GTT':'V',
    'GCA':'A', 'GCC':'A', 'GCG':'A', 'GCT':'A',
    'GAC':'D', 'GAT':'D', 'GAA':'E', 'GAG':'E',
    'GGA':'G', 'GGC':'G', 'GGG':'G', 'GGT':'G',
    'TCA':'S', 'TCC':'S', 'TCG':'S', 'TCT':'S',
    'TTC':'F', 'TTT':'F', 'TTA':'L', 'TTG':'L',
    'TAC':'Y', 'TAT':'Y', 'TAA':'*', 'TAG':'*',
    'TGC':'C', 'TGT':'C', 'TGA':'*', 'TGG':'W',
  }

  protein =""
  for i in range(0, len(seq), 3):
    codon = seq[i:i + 3]
    protein += table[codon]
  return protein

def seq_append(strand, frame, orf, pos_start, orf_len, orf_nt):
  orf_len = len(orf_nt)
  return {
      "strand": strand,
      "frame": frame + 1,
      "orf": orf,
      "pos_start": pos_start + 1,
      "pos_end": pos_start + orf_len,
      "orf_len": orf_len,
      "orf_nt": orf_nt
  }

def find_protein(record, min_codons):
  start_codon = "ATG"
  stop_codon = ["TAA", "TGA", "TAG"]
  min_nt = min_codons * 3
  seqs = []

  record_seq = record["seq"].upper()

  for strand, record_seq in [(1, record_seq), (-1, reversed_complement(record_seq))]:
    record_seq_len = len(record_seq)
    
    # iterate over ORFs
    for frame in range(0, 3):
      
      # iterate over seq
      seq = ""
      pos_start = 0
      orf = 0
      for pos in range(frame, record_seq_len, 3):
        posf = pos + 3
        
        act = ""
        if posf > record_seq_len:
          seq = ""
          continue

        if record_seq[pos:posf] == start_codon:
          act = "ADD"
          if not seq:
            pos_start = pos
        elif seq:
          if record_seq[pos:posf] in stop_codon:
            act = "END"
          else:
            act = "ADD"
        
        if act == "ADD":
          seq += record_seq[pos:posf]
        elif act == "END":
          # seq += record_seq[pos:posf]

          seq_len = len(seq)
          if seq_len >= min_nt:
            orf += 1
            seqs.append(seq_append(strand, frame, orf, pos_start, seq_len, seq))
          seq = ""
  
  return seqs

def print_text(filename,min_codons):
  for record in read_fasta(filename):
    seqs1 = find_protein(record,min_codons)

    print(record["id"])
    print("ORFs found: %d" % len(seqs1))
    print()

    for seq1 in seqs1:
      print(">ORF number %d in reading frame %d on the %s strand extends from base %d to base %d." % (
          seq1["orf"], seq1["frame"], 
          "direct" if seq1["strand"] == 1 else "reverse",
          seq1["pos_start"], seq1["pos_end"]
      ))
      print(seq1["seq"])
      print(translate(seq1["seq"]))
      print()

#print_text()

def print_csv(filename,min_codons):
  with io.StringIO() as csvfile:
    fieldnames = ["strand", "frame", "orf",
                  "pos_start", "pos_end", "seq_pos", "seq_id", "seq_len", "orf_len", "orf_nt", "orf_aa"]
    writer = csv.DictWriter(csvfile, fieldnames=fieldnames)
    writer.writeheader()

    for (seq_pos, record) in enumerate(read_fasta(filename)):
      seqs1 = find_protein(record, min_codons)
      record_len = len(record['seq'])
      
      for seq1 in seqs1:
        seq1["seq_pos"] = seq_pos
        seq1["seq_id"] = record["id"]
        seq1["seq_len"] = record_len
        seq1["orf_aa"] = translate(seq1["orf_nt"])
        writer.writerow(seq1)
    
    #print(csvfile.getvalue())
    # with open(filename.replace('fa','csv'),'w') as f:
    #  f.write(csvfile.getvalue())
    return pd.read_csv(StringIO(csvfile.getvalue()))

def getCountatcg(filename):
  with open(filename,'r') as f:
    content = f.readlines()
  mydic = {}
  name=''
  for line in content:
    if '>' in line:
      name = line.rstrip('\n').replace('>','')
      mydic[name] = []
    else:
      mydic[name] +=line.rstrip('\n')
  namelist = []
  atcglist = []
  for key in mydic:
    tot = len(mydic[key])
    c = Counter(mydic[key])
    for ckey in c:
      namelist += [key]*int((c[ckey]/tot)*100)
      atcglist += [ckey]*int((c[ckey]/tot)*100)
  df = pd.DataFrame()
  df['seqs'] = namelist
  df['atcg'] = atcglist
  return df 

#print_csv()

"""# rodando para um caso de teste"""

#filename = '/home/alisson/work/github_chiquitto_ProkaORFShiny/samples/Random1.fa'
#min_codons = 15
# start_codon = "ATG"
# stop_codon = ["TAA", "TGA", "TAG"]

# Escrevendo csv

#print( print_csv(filename,min_codons) )
