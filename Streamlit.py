import streamlit as st
import snowflake.connector

# Snowflake connection details
def create_connection():
    conn = snowflake.connector.connect(
        user="YOUR_USERNAME",
        password="YOUR_PASSWORD",
        account="YOUR_ACCOUNT_NAME",
        warehouse="YOUR_WAREHOUSE",
        database="YOUR_DATABASE",
        schema="YOUR_SCHEMA"
    )
    return conn

# Query Snowflake to classify support tickets
def classify_request(conn, request):
    query = f"""
    SELECT snowflake.cortex.complete(
        'snowflake_llm_poc.PUBLIC.SUPPORT_TICKETS_FINETUNED_MISTRAL_7B',
        CONCAT(
            'You are an agent that helps organize requests that come to our support team.

            The request category is the reason why the customer reached out. These are the possible types of request categories:

            Roaming fees
            Slow data speed
            Lost phone
            Add new line
            Closing account

            Try doing it for this request and return only the request category only.
            <request>', '{request}', '</request>'
        )
    ) AS classification_result;
    """
    cursor = conn.cursor()
    cursor.execute(query)
    result = cursor.fetchone()
    cursor.close()
    return result[0] if result else "No result"

# Streamlit app
def main():
    st.title("Support Ticket Classification")
    st.write("This app uses Snowflake Cortex AI to classify support tickets into predefined categories.")

    # Input field for request
    request = st.text_area(
        "Enter the support ticket request:",
        placeholder="Describe the customer's issue here..."
    )

    if st.button("Classify Request"):
        if request.strip():
            try:
                # Connect to Snowflake and classify the request
                with create_connection() as conn:
                    classification = classify_request(conn, request)
                st.success(f"Classification Result: {classification}")
            except Exception as e:
                st.error(f"An error occurred: {e}")
        else:
            st.warning("Please enter a valid support ticket request.")

if __name__ == "__main__":
    main()
