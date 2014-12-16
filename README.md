Bing Search API for NodeJS
==========================
[![Build Status](https://travis-ci.org/dudleycarr/bing-search.svg)](https://travis-ci.org/dudleycarr/bing-search)

Features
--------

* Support **all** [Bing Search API](https://datamarket.azure.com/dataset/bing/search) verticals
    * Web
    * Image
    * Video
    * News
    * Related search
    * Spelling suggestions
    * Composite
* **Accurate counts** for each vertical. Web being the most problematic.
* Abstracted pagination for **large results.**
* **Concurrent** requests for results sets larger than 50 results.
* **Normalized** JSON results.
* Automatically uses `gzip`

Getting Started
---------------

1. Sign-up for an account the [Bing Search API](https://datamarket.azure.com/dataset/bing/search) via the Azure Market Place.
2. Use the [Azure Data Explorer for the Bing Search API](https://datamarket.azure.com/dataset/explore/bing/search) to see the results you can expect returned via the API.
3. Grab the account key from the Data Explorer.

Install
-------

```bash
$ npm install bing.search --save
```

Usage
-----

Basic example:
```javascript
var Search = require('bing.search');
var util = require('util');

search = new Search('account_key_123');

search.web('Tutta Bella Neapolitan Pizzeria',
  {top: 5},
  function(err, results) {
    console.log(util.inspect(results, 
      {colors: true, depth: null}));
  }
);
```

Output:
```javascript
[ { id: 'e66c09f5-3317-4227-aee7-bc5dec3aec43',
    title: 'Tutta Bella Neapolitan Pizzeria',
    description: 'Neapolitan pizzeria located...',
    displayUrl: 'tuttabellapizza.com',
    url: 'http://tuttabellapizza.com/' },
  { id: '94b5a08a-6148-4832-9077-98245f3e1b42',
    title: 'Tutta Bella Neapolitan Pizzeria - Columbia City',
    description: 'Tutta Bella Columbia City...',
    displayUrl: 'www.tuttabella.com/tuttabellacc/index.php',
    url: 'http://www.tuttabella.com/tuttabellacc/index.php' },
  { id: '11bf839d-ce9e-4215-9b55-d663bdd17b98',
    title: 'Tutta Bella Menu - Tutta Bella Neapolitan Pizzeria',
    description: 'Tutta Bella Neapolitan Pizzeria - Columbia City...',
    displayUrl: 'www.tuttabella.com/menu',
    url: 'http://www.tuttabella.com/menu/' },
  { id: 'da706086-5566-414b-b70f-2648e762cdf6',
    title: 'Tutta Bella Neapolitan Pizzeria - Crossroads',
    description: 'Ciao! Come visit us in our newest Tutta Bella location...',
    displayUrl: 'tuttabella.com/tuttabellacr/index.php',
    url: 'http://tuttabella.com/tuttabellacr/index.php' },
  { id: '4d4d0961-bdd1-406f-aa80-39d067318c49',
    title: 'Tutta Bella Neapolitan Pizzeria - Westlake',
    description: 'Parking. Tutta Bella validates guest parking...',
    displayUrl: 'www.tuttabella.com/TuttaBellaWL',
    url: 'http://www.tuttabella.com/TuttaBellaWL/' } ]
```

### new Search(accountKey, [parallelLimit], [useGzip])

The `accountKey` is Bing Search API account key provided by the Azure market
place. `parallelLimit` is the number of search results pages fetched in
parallel for a given query. The default is `10`. `useGzip` defaults to true.

Available methods:

* `counts(query, [options], callback)` . `query` is the search query. `options` is a dictionary with permissible values below -- it can be ommitted. `callback` takes an error and a results object.  

  The following options can be provided:
  * `market`
  * `sources` defaults to all sources.

  Format of results to callback:
  ```javascript
  { web: 334,
    image: 20400,
    video: 33400,
    news: 1460 }
  ```

* `web(query, [options], callback)` "Web" only search. `query` is the search query. `options` is a dictionary with permissible values below -- it can be ommitted. `callback` takes an error and a results object.  

  The following options can be provided:
  * `top` default is 50
  * `skip` default is 0
  * `market`

  Format of results to callback:
  ```javascript
  [ { id: '...',
      title: '...',
      description: '...',
      url: '...' },
     ...
  ]

  ```
* `images(query, [options], callback)` "Image" only search. `query` is the search query. `options` is a dictionary with permissible values below -- it can be ommitted. `callback` takes an error and a results object.

  The following options can be provided:
  * `top` default is 50
  * `skip` default is 0
  * `market`

  Format of results to callback:
  ```javascript
  [ { id: '...',
      title: '...',
      url: 'http://...',
      sourceUrl: 'http://...',
      displayUrl: '...',
      width: 1025,
      height: 1600,
      size: 136701,
      type: 'image/jpeg',
      thumbnail:
      { url: 'http://...',
        type: 'image/jpg',
        width: 192,
        height: 300,
        size: 6946 }
    },
     ...
  ]
  ```
* `videos(query, [options], callback)` "Video" only search. `query` is the search query. `options` is a dictionary with permissible values below -- it can be ommitted. `callback` takes an error and a results object.

  The following options can be provided:
  * `top` default is 50
  * `skip` default is 0
  * `market`

  Format of results to callback:
  ```javascript
  [ { id: '...',
      title: '...',
      url: 'https://...',
      displayUrl: 'http://...',
      runtime: 62000,
      thumbnail:
      { url: 'http://...',
        type: 'image/jpg',
        width: 160,
        height: 120,
        size: 18423 } },
     ...
  ]
  ```
* `news(query, [options], callback)` "News" only search. `query` is the search query. `options` is a dictionary with permissible values below -- it can be ommitted. `callback` takes an error and a results object.

  The following options can be provided:
  * `top` default is 15
  * `skip` default is 0
  * `market`

  Format of results to callback:
  ```javascript
  [ { id: '...',
      title: '...',
      source: '...',
      url: 'http://...',
      description: '...',
      date: [Date Object] },
     ...
  ]
  ```
* `related(query, [options], callback)` "RelatedSearch" only search. `query` is the search query. `options` is a dictionary with permissible values below -- it can be ommitted. `callback` takes an error and a results object.

  The following options can be provided:
  * `top` default is 50
  * `skip` default is 0
  * `market`

  Format of results to callback:
  ```javascript
  [ { query: '...',
      url: 'http://...' },
     ...
  ]
  ```

* `spelling(query, [options], callback)` "SpellingSuggestions" only search. `query` is the search query. `options` is a dictionary with permissible values below -- it can be ommitted. `callback` takes an error and a results object.

  The following options can be provided:
  * `top` default is 50
  * `skip` default is 0
  * `market`

  `callback`'s result is a list of alternate query spellings as strings.

* `composite(query, [options], callback)` "Composite" searches all of the provided sources. `query` is the search query. `options` is a dictionary with permissible values below -- it can be ommitted. `callback` takes an error and a results object.

  The following options can be provided:
  * `top` default is 50
  * `skip` default is 0
  * `sources` defaults to all sources
  * `market`

  Format of results to callback:
  ```javascript
  { web: [ ... ],
    images: [ ... ],
    videos: [ ... ],
    news: [ ... ],
    spelling: [ ... ],
    related: [ ... ]
  }
  ```

  Each of the sources with in the composite result follows is the same format
  returned by each of the individual source searches.

### 

Debugging
---------


TODOs
-----

* Better API error messages
* Support WebSearchOptions
* Support Adult params
* Support Latitude and Longitude
* Support WebFileType
* Support ImageFilters
* Support VideoFilters and VideoSortBy
* Support NewsCategory, NewsLocation, NewsSortBy
* Adjust https max sockets based on concurrent level
* Support smaller pagination for news

Changes
-------

* 1.0
  * Initial support for all Bing Search API sources
