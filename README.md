# Seating Chart App
[![License: MIT](https://img.shields.io/badge/License-MIT-lightgrey.svg)](https://opensource.org/license/mit)
![experimental](https://img.shields.io/badge/lifecycle-experimental-orange)
![year](https://img.shields.io/badge/year-2024-blue)

## Description
This app uses machine learning algorithms to make seating charts for teachers. The app allows you to upload a csv file and returns a seating chart to separate groups.

![Screenshot](/screenshots/screenshot_v0.1.png)

## Data Template
This repository contains both an [example dataset](/sc_testdata.csv) and a [template](/sc_template.csv) for creating your own rosters. Files MUST be in .csv format with the column names "name", "group", and "frontRow" (case-sensitive).

## Data Structure

The following structure should be used to format incoming data.

**name** is the name of the student.

**group** is type-agnostic and can be anything. It's treated as a factor, so as long as the groups are kept consistent and case sensitive you'll be fine. Students don't need to be in a group, it can be left empty and the student will automatically be assigned to the "Ungrouped" group.

**frontRow** is a true or false variable indicating that a student should sit in the front row, regardless of group. This is calculated before grouping, so it should still be fine.

### Example data

| name | group | frontRow |
| --- | --- | ---|
| Fred | 1 | FALSE |
| Wilma | | TRUE |
| Barney | A | FALSE |