# This Python script generates random datasets for testing purposes.
# It creates multiple CSV files with random data including names, ages, emails, phone numbers, dates, scores, and unique identifiers.
# The business requirement fulfilled by this script is to provide sample data for testing data processing and analysis applications.

import pandas as pd
import numpy as np
import random
import string
import uuid

range_value = 1000  # Number of records to generate


def generate_random_email(null_percent: float = 20):
    """
    Generate a random email address or return None based on the null_percent probability.

    :param null_percent: Probability percentage to return None instead of an email.
    :return: Random email address or None.
    """
    domains = ["gmail.com", "yahoo.com", "hotmail.com"]
    if random.random() * 100 < null_percent:
        return None
    # Generate a random string for the email prefix and append a random domain
    return ''.join(random.choices(string.ascii_lowercase, k=random.randint(5, 7))) + '@' + random.choice(domains)


def generate_random_phone(null_percent: float = 20):
    """
    Generate a random phone number or return None based on the null_percent probability.

    :param null_percent: Probability percentage to return None instead of a phone number.
    :return: Random phone number or None.
    """
    if random.random() * 100 < null_percent:
        return None
    # Generate a random country code and a 10-digit phone number
    country_code = f"+{random.choice(['91', '01', '44', '81', '61'])}"
    phone_number = ''.join(random.choices(string.digits, k=10))
    return f"{country_code} {phone_number}"


def generate_random_date(null_percent: float = 20):
    """
    Generate a random date within a specified range or return None based on the null_percent probability.

    :param null_percent: Probability percentage to return None instead of a date.
    :return: Random date or None.
    """
    if random.random() * 100 < null_percent:
        return None
    start_date = pd.to_datetime('2020-01-01')
    end_date = pd.to_datetime('2023-01-01')
    # Generate a random date between start_date and end_date
    return start_date + (end_date - start_date) * random.random()


def generate_random_alphanumeric(length=8, null_percent: float = 20):
    """
    Generate a random alphanumeric string of specified length or return None based on the null_percent probability.

    :param length: Length of the alphanumeric string.
    :param null_percent: Probability percentage to return None instead of an alphanumeric string.
    :return: Random alphanumeric string or None.
    """
    if random.random() * 100 < null_percent:
        return None
    # Generate a random alphanumeric string of specified length
    return ''.join(random.choices(string.ascii_letters + string.digits, k=length))


def generate_random_name(null_percent: float = 20):
    """
    Generate a random name from a predefined list or return None based on the null_percent probability.

    :param null_percent: Probability percentage to return None instead of a name.
    :return: Random name or None.
    """
    if random.random() * 100 < null_percent:
        return None
    # Choose a random name from the predefined list
    return random.choice(['Alice', 'Bob', 'Charlie', 'David', 'Eve'])


def generate_random_age(null_percent: float = 20):
    """
    Generate a random age between 18 and 70 or return None based on the null_percent probability.

    :param null_percent: Probability percentage to return None instead of an age.
    :return: Random age or None.
    """
    if random.random() * 100 < null_percent:
        return None
    # Generate a random age between 18 and 70
    return random.randint(18, 70)


def generate_random_score(null_percent: float = 20):
    """
    Generate a random score between 0 and 100 or return None based on the null_percent probability.

    :param null_percent: Probability percentage to return None instead of a score.
    :return: Random score or None.
    """
    if random.random() * 100 < null_percent:
        return None
    # Generate a random score between 0 and 100
    return random.randint(0, 100)


def generate_random_boolean():
    """
    Generate a random boolean value.

    :return: Random boolean value (True or False).
    """
    # Randomly choose between True and False
    return random.choice([True, False])


def generate_unique_ids(count, length=5):
    """
    Generate a list of unique alphanumeric IDs.

    :param count: Number of unique IDs to generate.
    :param length: Length of each unique ID.
    :return: List of unique IDs.
    """
    unique_ids = set()
    while len(unique_ids) < count:
        # Generate a random unique ID and add it to the set
        uid = ''.join(random.choices(string.ascii_uppercase + string.digits, k=length))
        unique_ids.add(uid)
    return list(unique_ids)


# Create a dictionary with random data for each column
data = {
    'UniqueID': generate_unique_ids(range_value),
    'Name': [generate_random_name() for _ in range(range_value)],
    'Age': [generate_random_age() for _ in range(range_value)],
    'Email': [generate_random_email() for _ in range(range_value)],
    'Phone': [generate_random_phone() for _ in range(range_value)],
    'JoinDate': [generate_random_date() for _ in range(range_value)],
    'Score': [generate_random_score() for _ in range(range_value)],
    'ID': [uuid.uuid4() for _ in range(range_value)],
    'Flag': [generate_random_boolean() for _ in range(range_value)],
}

# Create a DataFrame from the generated data
df = pd.DataFrame(data)

n = 270
# sampled_rows = df.sample(n=n, replace=False)
# df_updated = pd.concat([df, sampled_rows], ignore_index=True)

# Save the generated DataFrame to a CSV file
df.to_csv('generated_dataset.csv', index=False)

# Create a subset of the data for another CSV file
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

# Create another subset of the data for a different CSV file
data2 = {
    'UniqueID': data['UniqueID'],
    'ID': data['ID'],
    'Score': data['Score'],
}
df2 = pd.DataFrame(data2)
df2.to_csv('generated_dataset2.csv', index=False)