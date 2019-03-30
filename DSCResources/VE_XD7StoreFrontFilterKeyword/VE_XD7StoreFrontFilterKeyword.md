
## XD7StoreFrontFilterKeyword

Sets up enumeration filtering basing on resource keywords.

### Syntax

```
XD7StoreFrontFilterKeyword [string]
{
    StoreName = [String]
    [ IncludeKeywords = [String[]] ]
    [ ExcludeKeywords = [String[]] ]
}
```

### Properties

* **StoreName**: StoreFront store name.
* **IncludeKeywords**: Whitelist filtering. Only resources having one of the keywords specified are enumerated.
* **ExcludeKeywords**: Blacklist filtering. Only resources not having any of the keywords specified are enumerated.

    **Note: the filtering can be either by white- or blacklist, not both at the same time.**

### Configuration

```
Configuration XD7Example {
    Import-DscResource -ModuleName XenDesktop7
    XD7StoreFrontFilterKeyword XD7StoreFrontFilterKeywordExample {
        StoreName = 'mock'
        IncludeKeywords = @('mock','support')
    }
}
```
