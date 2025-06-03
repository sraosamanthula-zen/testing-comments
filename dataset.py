# This Python script generates synthetic datasets with random values for testing purposes.
# It creates a main dataset and two subsets, saving them as CSV files. The datasets include
# random names, ages, emails, phone numbers, join dates, scores, unique IDs, and boolean flags.

import pandas as pd
import numpy as np
import random
import string
import uuid

range_value = 1000  # Number of records to generate for each dataset

def generate_random_email(null_percent: float = 20):
    """
    Generates a random email address or returns None based on the null_percent probability.

    :param null_percent: Probability percentage to return None instead of an email.
    :return: Random email address or None.
    """
    domains = ["gmail.com", "yahoo.com", "hotmail.com"]
    if random.random() * 100 < null_percent:
        return None
    return ''.join(random.choices(string.ascii_lowercase, k=random.randint(5, 7))) + '@' + random.choice(domains)

def generate_random_phone(null_percent: float = 20):
    """
    Generates a random phone number with a country code or returns None based on the null_percent probability.

    :param null_percent: Probability percentage to return None instead of a phone number.
    :return: Random phone number or None.
    """
    if random.random() * 100 < null_percent:
        return None
    country_code = f"+{random.choice(['91', '01', '44', '81', '61'])}"  # Random country code
    phone_number = ''.join(random.choices(string.digits, k=10))  # Random 10-digit number
    return f"{country_code} {phone_number}"

def generate_random_date(null_percent: float = 20):
    """
    Generates a random date between 2020-01-01 and 2023-01-01 or returns None based on the null_percent probability.

    :param null_percent: Probability percentage to return None instead of a date.
    :return: Random date or None.
    """
    if random.random() * 100 < null_percent:
        return None
    start_date = pd.to_datetime('2020-01-01')
    end_date = pd.to_datetime('2023-01-01')
    return start_date + (end_date - start_date) * random.random()  # Random date within the range

def generate_random_alphanumeric(length=8, null_percent: float = 20):
    """
    Generates a random alphanumeric string of specified length or returns None based on the null_percent probability.

    :param length: Length of the alphanumeric string.
    :param null_percent: Probability percentage to return None instead of an alphanumeric string.
    :return: Random alphanumeric string or None.
    """
    if random.random() * 100 < null_percent:
        return None
    return ''.join(random.choices(string.ascii_letters + string.digits, k=length))

def generate_random_name(null_percent: float = 20):
    """
    Selects a random name from a predefined list or returns None based on the null_percent probability.

    :param null_percent: Probability percentage to return None instead of a name.
    :return: Random name or None.
    """
    if random.random() * 100 < null_percent:
        return None
    return random.choice(['Alice', 'Bob', 'Charlie', 'David', 'Eve'])  # Random name selection

def generate_random_age(null_percent: float = 20):
    """
    Generates a random age between 18 and 70 or returns None based on the null_percent probability.

    :param null_percent: Probability percentage to return None instead of an age.
    :return: Random age or None.
    """
    if random.random() * 100 < null_percent:
        return None
    return random.randint(18, 70)  # Random age within the range

def generate_random_score(null_percent: float = 20):
    """
    Generates a random score between 0 and 100 or returns None based on the null_percent probability.

    :param null_percent: Probability percentage to return None instead of a score.
    :return: Random score or None.
    """
    if random.random() * 100 < null_percent:
        return None
    return random.randint(0, 100)  # Random score within the range

def generate_random_boolean():
    """
    Generates a random boolean value.

    :return: Random boolean value (True or False).
    """
    return random.choice([True, False])

def generate_unique_ids(count, length=5):
    """
    Generates a list of unique alphanumeric IDs.

    :param count: Number of unique IDs to generate.
    :param length: Length of each unique ID.
    :return: List of unique alphanumeric IDs.
    """
    unique_ids = set()
    while len(unique_ids) < count:
        uid = ''.join(random.choices(string.ascii_uppercase + string.digits, k=length))
        unique_ids.add(uid)  # Ensure uniqueness by using a set
    return list(unique_ids)

# Generate the main dataset with random values
data = {
    'UniqueID': generate_unique_ids(range_value),
    'Name': [generate_random_name() for _ in range(range_value)],
    'Age': [generate_random_age() for _ in range(range_value)],
    'Email': [generate_random_email() for _ in range(range_value)],
    'Phone': [generate_random_phone() for _ in range(range_value)],
    'JoinDate': [generate_random_date() for _ in range(range_value)],
    'Score': [generate_random_score() for _ in range(range_value)],
    'ID': [uuid.uuid4() for _ in range(range_value)],  # Generate unique UUIDs
    'Flag': [generate_random_boolean() for _ in range(range_value)],
}

df = pd.DataFrame(data)  # Create a DataFrame from the generated data

# Save the main dataset to a CSV file
df.to_csv('generated_dataset.csv', index=False)

# Generate a subset of the main dataset
data1 = {
    'UniqueID': data['UniqueID'],
    'ID': data['ID'],
    'Name': data['Name'],
    'Age': data['Age'],
    'Email': data['Email'],
    'Phone': data['Phone'],
    'JoinDate': data['JoinDate'],
    'Flag': data['Flag'],
}
df1 = pd.DataFrame(data1)  # Create a DataFrame for the subset
df1.to_csv('generated_dataset1.csv', index=False)  # Save the subset to a CSV file

# Generate another subset with different columns
data2 = {
    'UniqueID': data['UniqueID'],
    'ID': data['ID'],
    'Score': data['Score'],
}
df2 = pd.DataFrame(data2)  # Create a DataFrame for the second subset
df2.to_csv('generated_dataset2.csv', index=False)  # Save the second subset to a CSV file