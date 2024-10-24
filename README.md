# Seating Chart App
[![License: MIT](https://img.shields.io/badge/License-MIT-lightgrey.svg)](https://opensource.org/license/mit)
![experimental](https://img.shields.io/badge/lifecycle-experimental-orange)
![year](https://img.shields.io/badge/year-2024-blue)

## Description
This app makes seating charts for teachers. The app allows you to upload a csv file and returns a seating chart. 

The csv file you provide must be in a specific format, with columns for **name**, **group**, and **frontRow**. A template and an example data file are provided below.

This app is designed to **separate** members of the same group. Though, conversely it can also be used to group them, if group distance is set to 0.

There are inputs for the number of rows, number of columns, and group distance.
1. **Number of rows:** controls the number of rows in the seating chart
2. **Number of columns:** controls the number of columns in the seating chart
3. **Group distance:** controls the number of desks between members of the same group.

> If the group distance is set too high, especially on a small seating charts, students will fail to be seated according to the desired **group distance** and will be seated randomly instead.

### Screenshot
![Screenshot](/screenshots/screenshot_v0.2.png)


## Data
This repository contains both an [example dataset](/sc_testdata.csv) and a [template](/sc_template.csv) for creating your own rosters. Files MUST be in .csv format with the column names "name", "group", and "frontRow" (case-sensitive).

| Example | Template |
|---|---|
|![example_ss](/screenshots/screenshot_example_v1.png)|![template_ss](/screenshots/screenshot_template_v1.png)|


### Data Structure

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