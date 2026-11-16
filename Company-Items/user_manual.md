# CSC 2510 FINAL PROJECT USER MANUAL

**Team:** Golden Feather
**Members:** Grace Dixon, Ethan Bolton, Caden Gentry, Shane Heller
**Date:** 11/15/26


## System Requirements

    - **Target Environment:** Ubuntu 26.04
    - BASH v5.3.9
    - Internet connection for web scraping


## Starting the Program

    - **Run Command:** (enter command here)
    - Upon starting, the program checks for a licensing file, which allows the program to proceed on schedule if present
    - If the licensing file is missing, the user will be prompted for a key


## Interface

    - Menu-based UI that prompts the user for a choice
    - **Default Action**
        The default action in the scope of the project is to scrape the TN Tech Computer Science Faculty website and parse through the names to be created into user accounts.


## Web Scraper

    - **Purpose:**
        The web scraper retrieves the first and last name of each Computer Science faculty member at TN Tech.

    - **Website:** https://www.tntech.edu/engineering/programs/csc/faculty-and-staff.php

    - **How To Use:
        - (list here)
    
    - **Expected Output:
        The output of the web scraper should be the first and last names of all TN Tech Computer Science faculty members, omitting each title if a member of faculty is listed as having one.

## Username and Password Generation

    - Usernames will be generated in the following format: **firstname.lastname**
    - Example:
        First Name: "John"
        Last Name: "Smith"
        Username: john.smith
    
    - Passwords will be generated in the following format: **firstnamelastnameHALBERD**
    - Example:
        First Name: "John"
        Last Name: "Smith"
        Password: johnsmithHALBERD


## Automated User Creation

    - **Purpose:**
        The purpose of automated user creation is to create accounts based on what the scraper pulls from the website as opposed to direct user input.
    
    - **How To Use:**
        1) Run the website scraper to access the faculty information
        2) Verify names were parsed correctly
        3) Allow program to generate each account's information
        4) Review results
    
    - **Expected Results:**
        The results should consist of a username and a password for each faculty member scraped from the website.


## Add User Function

    - **Purpose:**
        The Add User function is meant to manually create an account that didn't originally come from the website, requiring user input
    
    - **How To Use:**
        1) Select the option for the Add User function
        2) Enter the first and last name of the account being manually created
        3) Allow the program to process the information and generate the username and password for the new account
    
    - **Expected Output:**
        The expected output for this function is a user account created similar to the ones brought in from the official website, consisting of the same information and credential formatting.


## Licensing

    - **Purpose:**
        The purpose of the licensing is to make sure user creation is authorized by requiring a key to make changes to the system.

    - Initially, the program will check to see if a licensing file exists in the directory.
        - If the file exists, the program continues to run.
        - If the file doesn't exist, the program prompts the user for a key to move any further.

    - The 16-digit key obfuscation will be handled by AI
        