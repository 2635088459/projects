# Import required libraries
from urllib.parse import urlparse  # This helps us break down URLs into parts (like domain, path)
from collections import Counter    # Counter is like a dictionary that counts things automatically
import json                       # This lets us read and write JSON files
import os                         # This helps us work with files and directories
from tld import get_tld           # This helps us get the domain parts of a URL
import ssl                        # This handles secure connections

class HARAnalyzer:
    def __init__(self, har_dir='output/har_files'):
        # Initialize the class with the directory where HAR files are stored
        self.har_dir = har_dir    # Store the directory path
        # Create counters to keep track of different things we find
        self.all_third_parties = Counter()         # Will count third-party domain occurrences
        self.all_third_party_cookies = Counter()   # Will count full cookie entries (domain:name)
        self.cookie_name_count = Counter()         # Will count just cookie names

    def get_second_level_domain(self, url):
        """Gets the main part of a domain (e.g., 'google' from 'www.google.com')"""
        try:
            # Add 'http://' if the URL doesn't have a protocol
            if not url.startswith('http'):
                url = f'http://{url}'
            # Try to get the domain parts
            res = get_tld(url, as_object=True, fail_silently=True)
            # Return the domain if we found it, None if we didn't
            if res:
                return res.domain
            return None
        except Exception:
            return None  # Return None if anything goes wrong

    def is_third_party(self, main_domain, request_domain):
        """Checks if a domain is different from the main website's domain"""
        # Get the main part of both domains
        main_sld = self.get_second_level_domain(main_domain)
        req_sld = self.get_second_level_domain(request_domain)
        
        # If we got both domains successfully, compare them
        if main_sld and req_sld:
            return main_sld != req_sld  # Return True if they're different
        return True  # If we couldn't get either domain, assume it's third-party

    def analyze_har_file(self, har_path):
        """Looks through a HAR file to find third-party domains and cookies"""
        try:
            # Open and read the HAR file
            with open(har_path, 'r') as f:
                har_data = json.load(f)
            
            # Get the main website's domain from the HAR file
            main_domain = urlparse(har_data['log']['pages'][0]['title']).netloc
            # If we couldn't get it from the title, try to get it from the filename
            if not main_domain:
                main_domain = os.path.basename(har_path).replace('.har', '').split('_', 2)[-1]
            
            # Create sets to store unique cookies we find in this file
            site_cookies = set()                # Store full cookie entries (domain:name)
            cookie_names_this_site = set()      # Store just cookie names
            
            # Look through each request in the HAR file
            for entry in har_data['log']['entries']:
                # Get the domain this request was made to
                request_url = entry['request']['url']
                request_domain = urlparse(request_url).netloc
                
                # Check if this is a third-party domain
                if self.is_third_party(main_domain, request_domain):
                    # Count this third-party domain request
                    self.all_third_parties[request_domain] += 1
                    
                    # Look for cookies in the request
                    for cookie in entry['request'].get('cookies', []):
                        # Create a unique key for this cookie (domain:name)
                        cookie_key = f"{request_domain}:{cookie['name']}"
                        site_cookies.add(cookie_key)
                        cookie_names_this_site.add(cookie['name'])
                    
                    # Look for cookies in the response
                    for cookie in entry['response'].get('cookies', []):
                        cookie_key = f"{request_domain}:{cookie['name']}"
                        site_cookies.add(cookie_key)
                        cookie_names_this_site.add(cookie['name'])
            
            # After checking all requests, update our counters
            # Count each unique cookie we found
            for cookie in site_cookies:
                self.all_third_party_cookies[cookie] += 1
            
            # Count each unique cookie name we found
            for cookie_name in cookie_names_this_site:
                self.cookie_name_count[cookie_name] += 1
                
        except Exception as e:
            # If anything goes wrong, print the error
            print(f"Error analyzing {har_path}: {str(e)}")

    def analyze_all_files(self):
        """Process all HAR files and show the results"""
        # Get a list of all HAR files in our directory
        har_files = [f for f in os.listdir(self.har_dir) if f.endswith('.har')]
        total_files = len(har_files)
        
        print(f"\nAnalyzing {total_files} HAR files...")
        
        # Process each HAR file one by one
        for i, har_file in enumerate(har_files, 1):
            # Get the full path to the file
            har_path = os.path.join(self.har_dir, har_file)
            # Analyze this file
            self.analyze_har_file(har_path)
            
            # Show progress every 100 files
            if i % 100 == 0:
                print(f"Processed {i}/{total_files} files")
        
        # Print the results in a nice format
        # First, show the top 10 third-party domains
        print("\n=== Top 10 Most Common Third-Party Domains ===")
        print("Rank  | Domain                               | Occurrences")
        print("-" * 60)
        for rank, (domain, count) in enumerate(self.all_third_parties.most_common(10), 1):
            print(f"{rank:<5d} | {domain:<35} | {count:>11d}")
        
        # Then show the top 10 cookies
        print("\n=== Top 10 Most Common Third-Party Cookies ===")
        print("Rank  | Cookie Name                          | Occurrences")
        print("-" * 60)
        # Keep track of cookies we've shown to avoid duplicates
        seen_names = set()
        rank = 1
        # Look through all cookies, sorted by most common first
        for cookie_full, count in self.all_third_party_cookies.most_common():
            # Split the cookie into domain and name parts
            domain, name = cookie_full.split(':', 1)
            # If we haven't shown this cookie name yet
            if name not in seen_names:
                seen_names.add(name)
                # Get the total times this cookie name appeared
                total_occurrences = self.cookie_name_count[name]
                # Print the information
                print(f"{rank:<5d} | {name:<35} | {total_occurrences:>11d}")
                rank += 1
                # Stop after showing 10 cookies
                if rank > 10:
                    break

def main():
    # Fix SSL certificate issues on macOS
    ssl._create_default_https_context = ssl._create_unverified_context
    
    # Create and run the analyzer
    analyzer = HARAnalyzer(har_dir='output/har_files')
    analyzer.analyze_all_files()

# This is where the program starts running
if __name__ == "__main__":
    main()