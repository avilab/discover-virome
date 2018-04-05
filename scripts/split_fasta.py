
# http://biopython.org/wiki/Split_large_file

from Bio import SeqIO

def batch_iterator(iterator, batch_size):
    """Returns lists of length batch_size.

    This can be used on any iterator, for example to batch up
    SeqRecord objects from Bio.SeqIO.parse(...), or to batch
    Alignment objects from Bio.AlignIO.parse(...), or simply
    lines from a file handle.

    This is a generator function, and it returns lists of the
    entries from the supplied iterator.  Each list will have
    batch_size entries, although the final list may be shorter.
    """
  entry = True  # Make sure we loop once
    while entry:
      batch = []
      while len(batch) < batch_size:
        try:
          entry = next(iterator)
          except StopIteration:
          entry = None
          if entry is None:
            # End of file
            break
            batch.append(entry)
          if batch:
            yield batch

for i, batch in enumerate(batch_iterator(SeqIO.parse(snakemake.input[0], "fasta"), snakemake.params["batch_size"])):
  filename = snakemake.params["stub"] % (i + 1)
  with open(filename, "w") as handle:
    count = SeqIO.write(batch, handle, "fasta")
