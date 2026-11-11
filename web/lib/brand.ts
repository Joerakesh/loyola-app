/**
 * Single place for the college identity used across the web app.
 *
 * To use a real photograph of the church instead of the illustration, put the
 * file in web/public/loyola/ (for example church.jpg) and change CHURCH_IMAGE.
 * Use a photo you have the rights to: the college's own, or one from Wikimedia
 * Commons with a licence that permits it (and keep the attribution it requires).
 */
export const BRAND = {
  name: "Loyola College",
  product: "Student portal",
  city: "Chennai",
  motto: "Ad majorem Dei gloriam",
  mottoMeaning: "For the greater glory of God",
} as const;

export const CHURCH_IMAGE = "/loyola/church.svg";
export const CHURCH_ALT = "Loyola church at dusk, with its two towers lit from within";
