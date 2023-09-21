/// @file FIRParameterNames.h
///
/// Predefined event parameter names.
///
/// Params supply information that contextualize Events. You can associate up to 25 unique Params
/// with each Event type. Some Params are suggested below for certain common Events, but you are
/// not limited to these. You may supply extra Params for suggested Events or custom Params for
/// Custom events. Param names can be up to 40 characters long, may only contain alphanumeric
/// characters and underscores ("_"), and must start with an alphabetic character. Param values can
/// be up to 100 characters long. The "firebase_", "google_", and "ga_" prefixes are reserved and
/// should not be used.

#import <Foundation/Foundation.h>

/// Game achievement ID (String).
/// <pre>
///     let params = [
///       AnalyticsParameterAchievementID : "10_matches_won",
///       // ...
///     ]
/// </pre>
static NSString *const kFIRParameterAchievementID NS_SWIFT_NAME(AnalyticsParameterAchievementID) =
    @"achievement_id";

/// The ad format (e.g. Banner, Interstitial, Rewarded, Native, Rewarded Interstitial, Instream).
/// (String).
/// <pre>
///     let params = [
///       AnalyticsParameterAdFormat : "Banner",
///       // ...
///     ]
/// </pre>
static NSString *const kFIRParameterAdFormat NS_SWIFT_NAME(AnalyticsParameterAdFormat) =
    @"ad_format";

/// Ad Network Click ID (String). Used for network-specific click IDs which vary in format.
/// <pre>
///     let params = [
///       AnalyticsParameterAdNetworkClickID : "1234567",
///       // ...
///     ]
/// </pre>
static NSString *const kFIRParameterAdNetworkClickID
    NS_SWIFT_NAME(AnalyticsParameterAdNetworkClickID) = @"aclid";

/// The ad platform (e.g. MoPub, IronSource) (String).
/// <pre>
///     let params = [
///       AnalyticsParameterAdPlatform : "MoPub",
///       // ...
///     ]
/// </pre>
static NSString *const kFIRParameterAdPlatform NS_SWIFT_NAME(AnalyticsParameterAdPlatform) =
    @"ad_platform";

/// The ad source (e.g. AdColony) (String).
/// <pre>
///     let params = [
///       AnalyticsParameterAdSource : "AdColony",
///       // ...
///     ]
/// </pre>
static NSString *const kFIRParameterAdSource NS_SWIFT_NAME(AnalyticsParameterAdSource) =
    @"ad_source";

/// The ad unit name (e.g. Banner_03) (String).
/// <pre>
///     let params = [
///       AnalyticsParameterAdUnitName : "Banner_03",
///       // ...
///     ]
/// </pre>
static NSString *const kFIRParameterAdUnitName NS_SWIFT_NAME(AnalyticsParameterAdUnitName) =
    @"ad_unit_name";

/// A product affiliation to designate a supplying company or brick and mortar store location
/// (String). <pre>
///     let params = [
///       AnalyticsParameterAffiliation : "Google Store",
///       // ...
///     ]
/// </pre>
static NSString *const kFIRParameterAffiliation NS_SWIFT_NAME(AnalyticsParameterAffiliation) =
    @"affiliation";

/// Campaign custom parameter (String). Used as a method of capturing custom data in a campaign.
/// Use varies by network.
/// <pre>
///     let params = [
///       AnalyticsParameterCP1 : "custom_data",
///       // ...
///     ]
/// </pre>
static NSString *const kFIRParameterCP1 NS_SWIFT_NAME(AnalyticsParameterCP1) = @"cp1";

/// The individual campaign name, slogan, promo code, etc. Some networks have pre-defined macro to
/// capture campaign information, otherwise can be populated by developer. Highly Recommended
/// (String).
/// <pre>
///     let params = [
///       AnalyticsParameterCampaign : "winter_promotion",
///       // ...
///     ]
/// </pre>
static NSString *const kFIRParameterCampaign NS_SWIFT_NAME(AnalyticsParameterCampaign) =
    @"campaign";

/// Campaign ID (String). Used for keyword analysis to identify a specific product promotion or
/// strategic campaign. This is a required key for GA4 data import.
/// <pre>
///     let params = [
///       AnalyticsParameterCampaignID : "7877652710",
///       // ...
///     ]
/// </pre>
static NSString *const kFIRParameterCampaignID NS_SWIFT_NAME(AnalyticsParameterCampaignID) =
    @"campaign_id";

/// Character used in game (String).
/// <pre>
///     let params = [
///       AnalyticsParameterCharacter : "beat_boss",
///       // ...
///     ]
/// </pre>
static NSString *const kFIRParameterCharacter NS_SWIFT_NAME(AnalyticsParameterCharacter) =
    @"character";

/// Campaign content (String).
static NSString *const kFIRParameterContent NS_SWIFT_NAME(AnalyticsParameterContent) = @"content";

/// Type of content selected (String).
/// <pre>
///     let params = [
///       AnalyticsParameterContentType : "news article",
///       // ...
///     ]
/// </pre>
static NSString *const kFIRParameterContentType NS_SWIFT_NAME(AnalyticsParameterContentType) =
    @"content_type";

/// Coupon code used for a purchase (String).
/// <pre>
///     let params = [
///       AnalyticsParameterCoupon : "SUMMER_FUN",
///       // ...
///     ]
/// </pre>
static NSString *const kFIRParameterCoupon NS_SWIFT_NAME(AnalyticsParameterCoupon) = @"coupon";

/// Creative Format (String). Used to identify the high-level classification of the type of ad
/// served by a specific campaign.
/// <pre>
///     let params = [
///       AnalyticsParameterCreativeFormat : "display",
///       // ...
///     ]
/// </pre>
static NSString *const kFIRParameterCreativeFormat NS_SWIFT_NAME(AnalyticsParameterCreativeFormat) =
    @"creative_format";

/// The name of a creative used in a promotional spot (String).
/// <pre>
///     let params = [
///       AnalyticsParameterCreativeName : "Summer Sale",
///       // ...
///     ]
/// </pre>
static NSString *const kFIRParameterCreativeName NS_SWIFT_NAME(AnalyticsParameterCreativeName) =
    @"creative_name";

/// The name of a creative slot (String).
/// <pre>
///     let params = [
///       AnalyticsParameterCreativeSlot : "summer_banner2",
///       // ...
///     ]
/// </pre>
static NSString *const kFIRParameterCreativeSlot NS_SWIFT_NAME(AnalyticsParameterCreativeSlot) =
    @"creative_slot";

/// Currency of the purchase or items associated with the event, in 3-letter
/// <a href="http://en.wikipedia.org/wiki/ISO_4217#Active_codes"> ISO_4217</a> format (String).
/// <pre>
///     let params = [
///       AnalyticsParameterCurrency : "USD",
///       // ...
///     ]
/// </pre>
static NSString *const kFIRParameterCurrency NS_SWIFT_NAME(AnalyticsParameterCurrency) =
    @"currency";

/// Flight or Travel destination (String).
/// <pre>
///     let params = [
///       AnalyticsParameterDestination : "Mountain View, CA",
///       // ...
///     ]
/// </pre>
static NSString *const kFIRParameterDestination NS_SWIFT_NAME(AnalyticsParameterDestination) =
    @"destination";

/// Monetary value of discount associated with a purchase (Double).
/// <pre>
///     let params = [
///       AnalyticsParameterDiscount : 2.0,
///       AnalyticsParameterCurrency : "USD",  // e.g. $2.00 USD
///       // ...
///     ]
/// </pre>
static NSString *const kFIRParameterDiscount NS_SWIFT_NAME(AnalyticsParameterDiscount) =
    @"discount";

/// The arrival date, check-out date or rental end date for the item. This should be in
/// YYYY-MM-DD format (String).
/// <pre>
///     let params = [
///       AnalyticsParameterEndDate : "2015-09-14",
///       // ...
///     ]
/// </pre>
static NSString *const kFIRParameterEndDate NS_SWIFT_NAME(AnalyticsParameterEndDate) = @"end_date";

/// Indicates that the associated event should either extend the current session or start a new
/// session if no session was active when the event was logged. Specify 1 to extend the current
/// session or to start a new session; any other value will not extend or start a session.
/// <pre>
///     let params = [
///       AnalyticsParameterExtendSession : 1,
///       // ...
///     ]
/// </pre>
static NSString *const kFIRParameterExtendSession NS_SWIFT_NAME(AnalyticsParameterExtendSession) =
    @"extend_session";

/// Flight number for travel events (String).
/// <pre>
///     let params = [
///       AnalyticsParameterFlightNumber : "ZZ800",
///       // ...
///     ]
/// </pre>
static NSString *const kFIRParameterFlightNumber NS_SWIFT_NAME(AnalyticsParameterFlightNumber) =
    @"flight_number";

/// Group/clan/guild ID (String).
/// <pre>
///     let params = [
///       AnalyticsParameterGroupID : "g1",
///       // ...
///     ]
/// </pre>
static NSString *const kFIRParameterGroupID NS_SWIFT_NAME(AnalyticsParameterGroupID) = @"group_id";

/// The index of the item in a list (Int).
/// <pre>
///     let params = [
///       AnalyticsParameterIndex : 5,
///       // ...
///     ]
/// </pre>
static NSString *const kFIRParameterIndex NS_SWIFT_NAME(AnalyticsParameterIndex) = @"index";

/// Item brand (String).
/// <pre>
///     let params = [
///       AnalyticsParameterItemBrand : "Google",
///       // ...
///     ]
/// </pre>
static NSString *const kFIRParameterItemBrand NS_SWIFT_NAME(AnalyticsParameterItemBrand) =
    @"item_brand";

/// Item category (context-specific) (String).
/// <pre>
///     let params = [
///       AnalyticsParameterItemCategory : "pants",
///       // ...
///     ]
/// </pre>
static NSString *const kFIRParameterItemCategory NS_SWIFT_NAME(AnalyticsParameterItemCategory) =
    @"item_category";

/// Item Category (context-specific) (String).
/// <pre>
///     let params = [
///       AnalyticsParameterItemCategory2 : "pants",
///       // ...
///     ]
/// </pre>
static NSString *const kFIRParameterItemCategory2 NS_SWIFT_NAME(AnalyticsParameterItemCategory2) =
    @"item_category2";

/// Item Category (context-specific) (String).
/// <pre>
///     let params = [
///       AnalyticsParameterItemCategory3 : "pants",
///       // ...
///     ]
/// </pre>
static NSString *const kFIRParameterItemCategory3 NS_SWIFT_NAME(AnalyticsParameterItemCategory3) =
    @"item_category3";

/// Item Category (context-specific) (String).
/// <pre>
///     let params = [
///       AnalyticsParameterItemCategory4 : "pants",
///       // ...
///     ]
/// </pre>
static NSString *const kFIRParameterItemCategory4 NS_SWIFT_NAME(AnalyticsParameterItemCategory4) =
    @"item_category4";

/// Item Category (context-specific) (String).
/// <pre>
///     let params = [
///       AnalyticsParameterItemCategory5 : "pants",
///       // ...
///     ]
/// </pre>
static NSString *const kFIRParameterItemCategory5 NS_SWIFT_NAME(AnalyticsParameterItemCategory5) =
    @"item_category5";

/// Item ID (context-specific) (String).
/// <pre>
///     let params = [
///       AnalyticsParameterItemID : "SKU_12345",
///       // ...
///     ]
/// </pre>
static NSString *const kFIRParameterItemID NS_SWIFT_NAME(AnalyticsParameterItemID) = @"item_id";

/// The ID of the list in which the item was presented to the user (String).
/// <pre>
///     let params = [
///       AnalyticsParameterItemListID : "ABC123",
///       // ...
///     ]
/// </pre>
static NSString *const kFIRParameterItemListID NS_SWIFT_NAME(AnalyticsParameterItemListID) =
    @"item_list_id";

/// The name of the list in which the item was presented to the user (String).
/// <pre>
///     let params = [
///       AnalyticsParameterItemListName : "Related products",
///       // ...
///     ]
/// </pre>
static NSString *const kFIRParameterItemListName NS_SWIFT_NAME(AnalyticsParameterItemListName) =
    @"item_list_name";

/// Item Name (context-specific) (String).
/// <pre>
///     let params = [
///       AnalyticsParameterItemName : "jeggings",
///       // ...
///     ]
/// </pre>
static NSString *const kFIRParameterItemName NS_SWIFT_NAME(AnalyticsParameterItemName) =
    @"item_name";

/// Item variant (String).
/// <pre>
///     let params = [
///       AnalyticsParameterItemVariant : "Black",
///       // ...
///     ]
/// </pre>
static NSString *const kFIRParameterItemVariant NS_SWIFT_NAME(AnalyticsParameterItemVariant) =
    @"item_variant";

/// The list of items involved in the transaction expressed as `[[String: Any]]`.
/// <pre>
///     let params = [
///       AnalyticsParameterItems : [
///         [AnalyticsParameterItemName : "jeggings", AnalyticsParameterItemCategory : "pants"],
///         [AnalyticsParameterItemName : "boots", AnalyticsParameterItemCategory : "shoes"],
///       ],
///     ]
/// </pre>
static NSString *const kFIRParameterItems NS_SWIFT_NAME(AnalyticsParameterItems) = @"items";

/// Level in game (Int).
/// <pre>
///     let params = [
///       AnalyticsParameterLevel : 42,
///       // ...
///     ]
/// </pre>
static NSString *const kFIRParameterLevel NS_SWIFT_NAME(AnalyticsParameterLevel) = @"level";

/// The name of a level in a game (String).
/// <pre>
///     let params = [
///       AnalyticsParameterLevelName : "room_1",
///       // ...
///     ]
/// </pre>
static NSString *const kFIRParameterLevelName NS_SWIFT_NAME(AnalyticsParameterLevelName) =
    @"level_name";

/// Location (String). The Google <a href="https://developers.google.com/places/place-id">Place ID
/// </a> that corresponds to the associated event. Alternatively, you can supply your own custom
/// Location ID.
/// <pre>
///     let params = [
///       AnalyticsParameterLocation : "ChIJiyj437sx3YAR9kUWC8QkLzQ",
///       // ...
///     ]
/// </pre>
static NSString *const kFIRParameterLocation NS_SWIFT_NAME(AnalyticsParameterLocation) =
    @"location";

/// The location associated with the event. Preferred to be the Google
/// <a href="https://developers.google.com/places/place-id">Place ID</a> that corresponds to the
/// associated item but could be overridden to a custom location ID string.(String).
/// <pre>
///     let params = [
///       AnalyticsParameterLocationID : "ChIJiyj437sx3YAR9kUWC8QkLzQ",
///       // ...
///     ]
/// </pre>
static NSString *const kFIRParameterLocationID NS_SWIFT_NAME(AnalyticsParameterLocationID) =
    @"location_id";

/// Marketing Tactic (String). Used to identify the targeting criteria applied to a specific
/// campaign.
/// <pre>
///     let params = [
///       AnalyticsParameterMarketingTactic : "Remarketing",
///       // ...
///     ]
/// </pre>
static NSString *const kFIRParameterMarketingTactic
    NS_SWIFT_NAME(AnalyticsParameterMarketingTactic) = @"marketing_tactic";

/// The advertising or marketing medium, for example: cpc, banner, email, push. Highly recommended
/// (String).
/// <pre>
///     let params = [
///       AnalyticsParameterMedium : "email",
///       // ...
///     ]
/// </pre>
static NSString *const kFIRParameterMedium NS_SWIFT_NAME(AnalyticsParameterMedium) = @"medium";

/// A particular approach used in an operation; for example, "facebook" or "email" in the context
/// of a sign_up or login event. (String).
/// <pre>
///     let params = [
///       AnalyticsParameterMethod : "google",
///       // ...
///     ]
/// </pre>
static NSString *const kFIRParameterMethod NS_SWIFT_NAME(AnalyticsParameterMethod) = @"method";

/// Number of nights staying at hotel (Int).
/// <pre>
///     let params = [
///       AnalyticsParameterNumberOfNights : 3,
///       // ...
///     ]
/// </pre>
static NSString *const kFIRParameterNumberOfNights
    NS_SWIFT_NAME(AnalyticsParameterNumberOfNights) = @"number_of_nights";

/// Number of passengers traveling (Int).
/// <pre>
///     let params = [
///       AnalyticsParameterNumberOfPassengers : 11,
///       // ...
///     ]
/// </pre>
static NSString *const kFIRParameterNumberOfPassengers
    NS_SWIFT_NAME(AnalyticsParameterNumberOfPassengers) = @"number_of_passengers";

/// Number of rooms for travel events (Int).
/// <pre>
///     let params = [
///       AnalyticsParameterNumberOfRooms : 2,
///       // ...
///     ]
/// </pre>
static NSString *const kFIRParameterNumberOfRooms NS_SWIFT_NAME(AnalyticsParameterNumberOfRooms) =
    @"number_of_rooms";

/// Flight or Travel origin (String).
/// <pre>
///     let params = [
///       AnalyticsParameterOrigin : "Mountain View, CA",
///       // ...
///     ]
/// </pre>
static NSString *const kFIRParameterOrigin NS_SWIFT_NAME(AnalyticsParameterOrigin) = @"origin";

/// The chosen method of payment (String).
/// <pre>
///     let params = [
///       AnalyticsParameterPaymentType : "Visa",
///       // ...
///     ]
/// </pre>
static NSString *const kFIRParameterPaymentType NS_SWIFT_NAME(AnalyticsParameterPaymentType) =
    @"payment_type";

/// Purchase price (Double).
/// <pre>
///     let params = [
///       AnalyticsParameterPrice : 1.0,
///       AnalyticsParameterCurrency : "USD",  // e.g. $1.00 USD
///       // ...
///     ]
/// </pre>
static NSString *const kFIRParameterPrice NS_SWIFT_NAME(AnalyticsParameterPrice) = @"price";

/// The ID of a product promotion (String).
/// <pre>
///     let params = [
///       AnalyticsParameterPromotionID : "ABC123",
///       // ...
///     ]
/// </pre>
static NSString *const kFIRParameterPromotionID NS_SWIFT_NAME(AnalyticsParameterPromotionID) =
    @"promotion_id";

/// The name of a product promotion (String).
/// <pre>
///     let params = [
///       AnalyticsParameterPromotionName : "Summer Sale",
///       // ...
///     ]
/// </pre>
static NSString *const kFIRParameterPromotionName NS_SWIFT_NAME(AnalyticsParameterPromotionName) =
    @"promotion_name";

/// Purchase quantity (Int).
/// <pre>
///     let params = [
///       AnalyticsParameterQuantity : 1,
///       // ...
///     ]
/// </pre>
static NSString *const kFIRParameterQuantity NS_SWIFT_NAME(AnalyticsParameterQuantity) =
    @"quantity";

/// Score in game (Int).
/// <pre>
///     let params = [
///       AnalyticsParameterScore : 4200,
///       // ...
///     ]
/// </pre>
static NSString *const kFIRParameterScore NS_SWIFT_NAME(AnalyticsParameterScore) = @"score";

/// Current screen class, such as the class name of the UIViewController, logged with screen_view
/// event and added to every event (String).
/// <pre>
///     let params = [
///       AnalyticsParameterScreenClass : "LoginViewController",
///       // ...
///     ]
/// </pre>
static NSString *const kFIRParameterScreenClass NS_SWIFT_NAME(AnalyticsParameterScreenClass) =
    @"screen_class";

/// Current screen name, such as the name of the UIViewController, logged with screen_view event and
/// added to every event (String).
/// <pre>
///     let params = [
///       AnalyticsParameterScreenName : "LoginView",
///       // ...
///     ]
/// </pre>
static NSString *const kFIRParameterScreenName NS_SWIFT_NAME(AnalyticsParameterScreenName) =
    @"screen_name";

/// The search string/keywords used (String).
/// <pre>
///     let params = [
///       AnalyticsParameterSearchTerm : "periodic table",
///       // ...
///     ]
/// </pre>
static NSString *const kFIRParameterSearchTerm NS_SWIFT_NAME(AnalyticsParameterSearchTerm) =
    @"search_term";

/// Shipping cost associated with a transaction (Double).
/// <pre>
///     let params = [
///       AnalyticsParameterShipping : 5.99,
///       AnalyticsParameterCurrency : "USD",  // e.g. $5.99 USD
///       // ...
///     ]
/// </pre>
static NSString *const kFIRParameterShipping NS_SWIFT_NAME(AnalyticsParameterShipping) =
    @"shipping";

/// The shipping tier (e.g. Ground, Air, Next-day) selected for delivery of the purchased item
/// (String).
/// <pre>
///     let params = [
///       AnalyticsParameterShippingTier : "Ground",
///       // ...
///     ]
/// </pre>
static NSString *const kFIRParameterShippingTier NS_SWIFT_NAME(AnalyticsParameterShippingTier) =
    @"shipping_tier";

/// The origin of your traffic, such as an Ad network (for example, google) or partner (urban
/// airship). Identify the advertiser, site, publication, etc. that is sending traffic to your
/// property. Highly recommended (String).
/// <pre>
///     let params = [
///       AnalyticsParameterSource : "InMobi",
///       // ...
///     ]
/// </pre>
static NSString *const kFIRParameterSource NS_SWIFT_NAME(AnalyticsParameterSource) = @"source";

/// Source Platform (String). Used to identify the platform responsible for directing traffic to a
/// given Analytics property (e.g., a buying platform where budgets, targeting criteria, etc. are
/// set, a platform for managing organic traffic data, etc.).
/// <pre>
///     let params = [
///       AnalyticsParameterSourcePlatform : "sa360",
///       // ...
///     ]
/// </pre>
static NSString *const kFIRParameterSourcePlatform NS_SWIFT_NAME(AnalyticsParameterSourcePlatform) =
    @"source_platform";

/// The departure date, check-in date or rental start date for the item. This should be in
/// YYYY-MM-DD format (String).
/// <pre>
///     let params = [
///       AnalyticsParameterStartDate : "2015-09-14",
///       // ...
///     ]
/// </pre>
static NSString *const kFIRParameterStartDate NS_SWIFT_NAME(AnalyticsParameterStartDate) =
    @"start_date";

/// The result of an operation. Specify 1 to indicate success and 0 to indicate failure (Int).
/// <pre>
///     let params = [
///       AnalyticsParameterSuccess : 1,
///       // ...
///     ]
/// </pre>
static NSString *const kFIRParameterSuccess NS_SWIFT_NAME(AnalyticsParameterSuccess) = @"success";

/// Tax cost associated with a transaction (Double).
/// <pre>
///     let params = [
///       AnalyticsParameterTax : 2.43,
///       AnalyticsParameterCurrency : "USD",  // e.g. $2.43 USD
///       // ...
///     ]
/// </pre>
static NSString *const kFIRParameterTax NS_SWIFT_NAME(AnalyticsParameterTax) = @"tax";

/// If you're manually tagging keyword campaigns, you should use utm_term to specify the keyword
/// (String).
/// <pre>
///     let params = [
///       AnalyticsParameterTerm : "game",
///       // ...
///     ]
/// </pre>
static NSString *const kFIRParameterTerm NS_SWIFT_NAME(AnalyticsParameterTerm) = @"term";

/// The unique identifier of a transaction (String).
/// <pre>
///     let params = [
///       AnalyticsParameterTransactionID : "T12345",
///       // ...
///     ]
/// </pre>
static NSString *const kFIRParameterTransactionID NS_SWIFT_NAME(AnalyticsParameterTransactionID) =
    @"transaction_id";

/// Travel class (String).
/// <pre>
///     let params = [
///       AnalyticsParameterTravelClass : "business",
///       // ...
///     ]
/// </pre>
static NSString *const kFIRParameterTravelClass NS_SWIFT_NAME(AnalyticsParameterTravelClass) =
    @"travel_class";

/// A context-specific numeric value which is accumulated automatically for each event type. This is
/// a general purpose parameter that is useful for accumulating a key metric that pertains to an
/// event. Examples include revenue, distance, time and points. Value should be specified as Int or
/// Double.
/// Notes: Values for pre-defined currency-related events (such as @c AnalyticsEventAddToCart)
/// should be supplied using Double and must be accompanied by a @c AnalyticsParameterCurrency
/// parameter. The valid range of accumulated values is
/// [-9,223,372,036,854.77, 9,223,372,036,854.77]. Supplying a non-numeric value, omitting the
/// corresponding @c AnalyticsParameterCurrency parameter, or supplying an invalid
/// <a href="https://goo.gl/qqX3J2">currency code</a> for conversion events will cause that
/// conversion to be omitted from reporting.
/// <pre>
///     let params = [
///       AnalyticsParameterValue : 3.99,
///       AnalyticsParameterCurrency : "USD",  // e.g. $3.99 USD
///       // ...
///     ]
/// </pre>
static NSString *const kFIRParameterValue NS_SWIFT_NAME(AnalyticsParameterValue) = @"value";

/// Name of virtual currency type (String).
/// <pre>
///     let params = [
///       AnalyticsParameterVirtualCurrencyName : "virtual_currency_name",
///       // ...
///     ]
/// </pre>
static NSString *const kFIRParameterVirtualCurrencyName
    NS_SWIFT_NAME(AnalyticsParameterVirtualCurrencyName) = @"virtual_currency_name";
