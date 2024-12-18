# Import all the libraries we need for our web crawler
from selenium import webdriver          # This helps us control the web browser
from browsermobproxy import Server     # This helps us capture network traffic (HAR files)
from selenium.webdriver.chrome.options import Options  # This lets us set up Chrome settings
import json                            # This helps us save HAR files (they're in JSON format)
import os                              # This helps us work with files and folders
import logging                         # This helps us keep track of what our program is doing
from datetime import datetime          # This helps us work with dates and times
import pandas as pd                    # This helps us read and work with CSV files

class WebCrawler:
    def __init__(self, output_dir='output'):
        """This sets up our web crawler when we first create it"""
        # Store where we want to save our files
        self.output_dir = output_dir
        # Create a specific folder for HAR files inside our output directory
        self.har_dir = os.path.join(output_dir, 'har_files')
        
        # Create the folders if they don't exist already
        # exist_ok=True means don't crash if the folder already exists
        os.makedirs(self.har_dir, exist_ok=True)
        
        # Set up logging so we can keep track of what happens
        # This creates a log file with the current date/time in its name
        logging.basicConfig(
            filename=f'{output_dir}/crawler_{datetime.now().strftime("%Y%m%d_%H%M%S")}.log',
            level=logging.INFO,  # This sets how detailed our logs should be
            format='%(asctime)s - %(levelname)s - %(message)s'  # This sets how the log messages look
        )

    def setup_crawler(self, proxy_path):
        """This sets up our browser and proxy to capture network traffic"""
        try:
            # Start the proxy server that will capture network traffic
            logging.info(f"Starting browsermob-proxy at: {proxy_path}")
            server = Server(proxy_path)  # Create the server
            server.start()              # Start it running
            # Create a proxy with special settings to handle all types of connections
            proxy = server.create_proxy(params=dict(trustAllServers=True))

            # Set up Chrome with special settings we need
            chrome_options = Options()
            chrome_options.add_argument(f'--proxy-server={proxy.proxy}')  # Use our proxy
            chrome_options.add_argument('--ignore-certificate-errors')    # Ignore SSL errors
            chrome_options.add_argument('--headless')  # Run Chrome without showing the window
            chrome_options.add_argument('--no-sandbox')  # More security settings
            chrome_options.add_argument('--disable-dev-shm-usage')  # More security settings

            # Start Chrome with our settings
            driver = webdriver.Chrome(options=chrome_options)
            driver.set_page_load_timeout(30)  # Wait maximum 30 seconds for pages to load
            
            logging.info("Successfully initialized browsermob-proxy and webdriver")
            return server, proxy, driver  # Return everything we set up
            
        except Exception as e:
            # If anything goes wrong, log the error
            logging.error(f"Error setting up crawler: {str(e)}")
            return None, None, None  # Return None for all three items if setup failed

    def read_sites(self, csv_path):
        """Read our list of websites from a CSV file"""
        try:
            # Read the CSV file and give names to the columns
            df = pd.read_csv(csv_path, names=['rank', 'domain'])
            # Get the first 1800 website domains as a list
            sites = df['domain'].tolist()[:1800]
            logging.info(f"Successfully read {len(sites)} sites from {csv_path}")
            return sites
        except Exception as e:
            # If anything goes wrong, log the error
            logging.error(f"Error reading CSV file {csv_path}: {str(e)}")
            return []  # Return an empty list if we couldn't read the file

    def crawl_sites(self, sites, proxy_path):
        """Visit each website and save its network traffic"""
        # Set up our crawler tools
        server, proxy, driver = self.setup_crawler(proxy_path)
        
        # Check if setup worked (all three items should exist)
        if not all([server, proxy, driver]):
            logging.error("Failed to setup crawler")
            return
        
        try:
            # Keep track of how many sites work and fail
            successful_crawls = 0
            failed_crawls = 0
            
            # Visit each website one by one
            for i, site in enumerate(sites, 1):  # enumerate gives us both number and site
                try:
                    # Create a name for this site's HAR file
                    har_name = f"site_{i}_{site.replace('.', '_')}"
                    # Tell proxy to start capturing traffic
                    proxy.new_har(har_name, options={
                        'captureHeaders': True,    # Save HTTP headers
                        'captureContent': True,    # Save content of requests
                        'captureCookies': True     # Save cookies
                    })
                    
                    # Add http:// to the site address if it doesn't have it
                    url = f"http://{site}" if not site.startswith(('http://', 'https://')) else site
                    logging.info(f"Crawling {i}/1800: {url}")
                    
                    # Visit the website
                    driver.get(url)
                    
                    # Save the captured traffic to a HAR file
                    har_path = os.path.join(self.har_dir, f"{har_name}.har")
                    with open(har_path, 'w') as f:
                        json.dump(proxy.har, f)
                    
                    successful_crawls += 1  # Count this as a success
                    logging.info(f"Successfully saved HAR for {url}")
                    
                except Exception as e:
                    failed_crawls += 1  # Count this as a failure
                    logging.error(f"Error crawling {site}: {str(e)}")
                    continue  # Skip to the next site
                
                # Show our progress every 100 sites
                if i % 100 == 0:
                    print(f"Progress: {i}/1800 sites processed")
                    print(f"Successful: {successful_crawls}, Failed: {failed_crawls}")
                
        finally:
            # Clean up when we're done (or if something goes wrong)
            if driver:
                driver.quit()  # Close the browser
            if server:
                server.stop()  # Stop the proxy server
            
            # Print final results
            print("\nCrawling completed!")
            print(f"Total sites processed: {len(sites)}")
            print(f"Successful crawls: {successful_crawls}")
            print(f"Failed crawls: {failed_crawls}")
            print(f"HAR files saved in: {self.har_dir}")

def main():
    # Create our web crawler
    crawler = WebCrawler()
    
    # Find our files relative to where this script is
    current_dir = os.path.dirname(os.path.abspath(__file__))
    csv_path = os.path.join(current_dir, 'top-1m.csv')  # The list of websites
    proxy_path = os.path.join(current_dir, 'browsermob-proxy/bin/browsermob-proxy')  # The proxy program
    
    # Read the list of websites
    sites = crawler.read_sites(csv_path)
    
    # If we got some websites, start crawling
    if sites:
        print(f"Successfully loaded {len(sites)} sites")
        print("Starting crawl process...")
        crawler.crawl_sites(sites, proxy_path)
    else:
        print("Failed to load sites list")

# This is where our program starts running
if __name__ == "__main__":
    main()