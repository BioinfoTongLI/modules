#!/usr/bin/env python
# -*- coding: utf-8 -*-
# Copyright (c) 2024 Wellcome Sanger Institute

"""

"""
from typing import List, Tuple
import fire
import numpy as np
import dask.dataframe as dd
from shapely.geometry import Point, MultiPoint
from shapely.ops import unary_union


def main(*csvs, ch_ind:int, prefix: str="merged", peak_radius: float = 1.5):
    df = dd.read_csv(csvs).compute()
    points= []
    for coord in df.values:
        points.append(Point(coord[1], coord[0]))
    # Create a buffer around each point
    buffers = [point.buffer(peak_radius) for point in points]

    # Merge overlapping buffers
    merged = unary_union(buffers)

    peaks = MultiPoint([g.centroid for g in merged.geoms])

    # Dump the merged multipolygon in WKT format
    with open(f"{prefix}_merged_peaks_ch_{ch_ind}.wkt", "w") as file:
        file.write(peaks.wkt)


if __name__ == "__main__":
    options = {
        "run" : main,
        "version" : "0.0.1"
    }
    fire.Fire(options)
