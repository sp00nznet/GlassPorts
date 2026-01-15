#!/usr/bin/env python3
"""
GlassPorts Sparse Image Converter
Converts Android sparse images to raw images

Based on the AOSP simg2img tool
"""

import sys
import struct
import os

SPARSE_HEADER_MAGIC = 0xED26FF3A
SPARSE_HEADER_SIZE = 28
CHUNK_HEADER_SIZE = 12

CHUNK_TYPE_RAW = 0xCAC1
CHUNK_TYPE_FILL = 0xCAC2
CHUNK_TYPE_DONT_CARE = 0xCAC3
CHUNK_TYPE_CRC32 = 0xCAC4


class SparseImage:
    def __init__(self, filename):
        self.filename = filename
        self.fd = open(filename, 'rb')
        self._parse_header()

    def _parse_header(self):
        header = self.fd.read(SPARSE_HEADER_SIZE)
        if len(header) < SPARSE_HEADER_SIZE:
            raise ValueError("File too small for sparse header")

        (
            magic,
            major_version,
            minor_version,
            file_hdr_sz,
            chunk_hdr_sz,
            self.blk_sz,
            self.total_blks,
            self.total_chunks,
            self.image_checksum
        ) = struct.unpack('<IHHHHIIII', header)

        if magic != SPARSE_HEADER_MAGIC:
            raise ValueError("Not a sparse image (bad magic)")

        if major_version != 1:
            raise ValueError(f"Unsupported sparse version {major_version}.{minor_version}")

        # Skip any extra header bytes
        if file_hdr_sz > SPARSE_HEADER_SIZE:
            self.fd.read(file_hdr_sz - SPARSE_HEADER_SIZE)

        self.chunk_hdr_sz = chunk_hdr_sz

    def _read_chunk_header(self):
        header = self.fd.read(CHUNK_HEADER_SIZE)
        if len(header) < CHUNK_HEADER_SIZE:
            return None

        chunk_type, reserved, chunk_sz, total_sz = struct.unpack('<HHII', header)

        # Skip extra chunk header bytes
        if self.chunk_hdr_sz > CHUNK_HEADER_SIZE:
            self.fd.read(self.chunk_hdr_sz - CHUNK_HEADER_SIZE)

        return {
            'type': chunk_type,
            'blocks': chunk_sz,
            'total_size': total_sz
        }

    def convert(self, output_filename):
        """Convert sparse image to raw image"""
        print(f"Converting {self.filename} to {output_filename}")
        print(f"Block size: {self.blk_sz}")
        print(f"Total blocks: {self.total_blks}")
        print(f"Total chunks: {self.total_chunks}")

        output_size = self.blk_sz * self.total_blks
        print(f"Output size: {output_size / (1024*1024):.1f} MB")

        with open(output_filename, 'wb') as out:
            # Pre-allocate output file
            out.truncate(output_size)
            out.seek(0)

            offset = 0
            for chunk_num in range(self.total_chunks):
                chunk = self._read_chunk_header()
                if chunk is None:
                    break

                chunk_data_size = chunk['blocks'] * self.blk_sz

                if chunk['type'] == CHUNK_TYPE_RAW:
                    # Raw data - copy directly
                    data_size = chunk['total_size'] - self.chunk_hdr_sz
                    data = self.fd.read(data_size)
                    out.seek(offset)
                    out.write(data)

                elif chunk['type'] == CHUNK_TYPE_FILL:
                    # Fill with 4-byte pattern
                    fill_data = self.fd.read(4)
                    fill_pattern = fill_data * (self.blk_sz // 4)
                    out.seek(offset)
                    for _ in range(chunk['blocks']):
                        out.write(fill_pattern)

                elif chunk['type'] == CHUNK_TYPE_DONT_CARE:
                    # Skip - leave as zeros
                    pass

                elif chunk['type'] == CHUNK_TYPE_CRC32:
                    # CRC32 chunk - skip
                    self.fd.read(4)

                offset += chunk_data_size

                # Progress
                progress = (chunk_num + 1) / self.total_chunks * 100
                print(f"\rProgress: {progress:.1f}%", end='', flush=True)

            print()  # Newline after progress

        print(f"Conversion complete: {output_filename}")
        return True

    def close(self):
        self.fd.close()


def is_sparse_image(filename):
    """Check if a file is a sparse image"""
    try:
        with open(filename, 'rb') as f:
            magic = struct.unpack('<I', f.read(4))[0]
            return magic == SPARSE_HEADER_MAGIC
    except:
        return False


def main():
    if len(sys.argv) < 3:
        print(f"Usage: {sys.argv[0]} <sparse_image> <output_raw_image>")
        sys.exit(1)

    input_file = sys.argv[1]
    output_file = sys.argv[2]

    if not os.path.exists(input_file):
        print(f"Error: Input file not found: {input_file}")
        sys.exit(1)

    if not is_sparse_image(input_file):
        print(f"Error: {input_file} is not a sparse image")
        sys.exit(1)

    try:
        sparse = SparseImage(input_file)
        sparse.convert(output_file)
        sparse.close()
    except Exception as e:
        print(f"Error: {e}")
        sys.exit(1)


if __name__ == '__main__':
    main()
