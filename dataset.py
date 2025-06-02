# This file generates synthetic datasets with random data for testing purposes.
# It fulfills the business requirement of creating mock data for various fields such as names, emails, phone numbers, etc.
# The generated data is saved into CSV files for further use in testing or data analysis.

import pandas as pd
import numpy as np
import random
import string
import uuid

range_value = 1000  # Number of records to generate for each dataset

def generate_random_email(null_percent: float = 20):
    """
    Generates a random email address or returns None based on the null_percent probability.

    :param null_percent: The probability (in percentage) that the result will be None.
    :return: A random email address or None.
    """
    domains = ["gmail.com", "yahoo.com", "hotmail.com"]
    # Determine if the result should be None based on the null_percent probability
    if random.random() * 100 < null_percent:
        return None
    # Generate a random email address
    return ''.join(random.choices(string.ascii_lowercase, k=random.randint(5, 7))) + '@' + random.choice(domains)

def generate_random_phone(null_percent: float = 20):
    """
    Generates a random phone number with a country code or returns None based on the null_percent probability.

    :param null_percent: The probability (in percentage) that the result will be None.
    :return: A random phone number or None.
    """
    # Determine if the result should be None based on the null_percent probability
    if random.random() * 100 < null_percent:
        return None
    # Generate a random phone number with a country code
    country_code = f"+{random.choice(['91', '01', '44', '81', '61'])}"
    phone_number = ''.join(random.choices(string.digits, k=10))
    return f"{country_code} {phone_number}"

def generate_random_date(null_percent: float = 20):
    """
    Generates a random date between 2020-01-01 and 2023-01-01 or returns None based on the null_percent probability.

    :param null_percent: The probability (in percentage) that the result will be None.
    :return: A random date or None.
    """
    # Determine if the result should be None based on the null_percent probability
    if random.random() * 100 < null_percent:
        return None
    # Generate a random date within the specified range
    start_date = pd.to_datetime('2020-01-01')
    end_date = pd.to_datetime('2023-01-01')
    return start_date + (end_date - start_date) * random.random()

def generate_random_alphanumeric(length=8, null_percent: float = 20):
    """
    Generates a random alphanumeric string of a given length or returns None based on the null_percent probability.

    :param length: The length of the alphanumeric string.
    :param null_percent: The probability (in percentage) that the result will be None.
    :return: A random alphanumeric string or None.
    """
    # Determine if the result should be None based on the null_percent probability
    if random.random() * 100 < null_percent:
        return None
    # Generate a random alphanumeric string of the specified length
    return ''.join(random.choices(string.ascii_letters + string.digits, k=length))

def generate_random_name(null_percent: float = 20):
    """
    Selects a random name from a predefined list or returns None based on the null_percent probability.

    :param null_percent: The probability (in percentage) that the result will be None.
    :return: A random name or None.
    """
    # Determine if the result should be None based on the null_percent probability
    if random.random() * 100 < null_percent:
        return None
    # Select a random name from the list
    return random.choice(['Alice', 'Bob', 'Charlie', 'David', 'Eve'])

def generate_random_age(null_percent: float = 20):
    """
    Generates a random age between 18 and 70 or returns None based on the null_percent probability.

    :param null_percent: The probability (in percentage) that the result will be None.
    :return: A random age or None.
    """
    # Determine if the result should be None based on the null_percent probability
    if random.random() * 100 < null_percent:
        return None
    # Generate a random age within the specified range
    return random.randint(18, 70)

def generate_random_score(null_percent: float = 20):
    """
    Generates a random score between 0 and 100 or returns None based on the null_percent probability.

    :param null_percent: The probability (in percentage) that the result will be None.
    :return: A random score or None.
    """
    # Determine if the result should be None based on the null_percent probability
    if random.random() * 100 < null_percent:
        return None
    # Generate a random score within the specified range
    return random.randint(0, 100)

def generate_random_boolean():
    """
    Randomly returns True or False.

    :return: A random boolean value.
    """
    # Randomly select True or False
    return random.choice([True, False])

def generate_unique_ids(count, length=5):
    """
    Generates a list of unique alphanumeric IDs.

    :param count: The number of unique IDs to generate.
    :param length: The length of each ID.
    :return: A list of unique alphanumeric IDs.
    """
    unique_ids = set()
    # Continue generating IDs until the desired count is reached
    while len(unique_ids) < count:
        uid = ''.join(random.choices(string.ascii_uppercase + string.digits, k=length))
        unique_ids.add(uid)
    return list(unique_ids)

# Generate synthetic data
data = {
    'UniqueID': generate_unique_ids(range_value),
    'Name': [generate_random_name() for _ in range(range_value)],
    'Age': [generate_random_age() for _ in range(range_value)],
    'Email': [generate_random_email() for _ in range(range_value)],
    'Phone': [generate_random_phone() for _ in range(range_value)],
    'JoinDate': [generate_random_date() for _ in range(range_value)],
    'Score': [generate_random_score() for _ in range(range_value)],
    'ID': [uuid.uuid4() for _ in range(range_value)],  # Generate unique UUIDs for each record
    'Flag': [generate_random_boolean() for _ in range(range_value)],
}

# Create a DataFrame from the generated data
df = pd.DataFrame(data)

n = 270  # Number of rows to sample
# sampled_rows = df.sample(n=n, replace=False)
# df_updated = pd.concat([df, sampled_rows], ignore_index=True)

# Save the DataFrame to a CSV file
# df_updated.to_csv('generated_dataset.csv', index=False)
df.to_csv('generated_dataset.csv', index=False)

# Create a second dataset with a subset of the fields
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
df1 = pd.DataFrame(data1)
df1.to_csv('generated_dataset1.csv', index=False)

# Create a third dataset with different fields
data2 = {
    'UniqueID': data['UniqueID'],
    'ID': data['ID'],
    'Score': data['Score'],
}
df2 = pd.DataFrame(data2)
df2.to_csv('generated_dataset2.csv', index=False)