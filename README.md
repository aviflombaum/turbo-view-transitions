# Turbo View Transitions

 I'm trying to improve my design engineering and have been practicing and looking for opportunities to flex and grow. One of my favorite new techniques is View Transitions, a simple way using CSS to animate transitions between states of the view, whether it's a full page reload or a DOM update. I happen to love JS but I want to write as little of it as possible, especially when it comes to adding and removing classes to facilitate animations. So view transitions really speak to me.

 Support for view transitions just hit the Turbo library with the release of Turbo 2.0. Along with DOM morphing support and combined with the rest of Rails, it's a powerful combination where you can achieve some impressive reactivity with really minimal effort, code, and complexity. Let me show you.

All the code for the application is on [GitHub](https://github.com/aviflombaum/turbo-view-transitions/tree/main) and you can see a demo of [view transitions with turbo](https://avi.nyc/turbo-view-transitions).

Everything here applies to Rails 7 and Turbo 2.0. It's worth upgrading your applications to the modern Rails stack (I just did an update from 6 to main and besides some stuff with webpacker, it really wasn't that bad).

## Setup

Our application has `Photo`s that have URLs and likes count. In `db/seed.rb` I create a few photos. There's also a `PhotosController` that has `index`, `show` and `update` actions. That's about all you need to know.

## Classic View Transitions

The transition we want to implement is the one between the `index` and `show` views. When you click on a photo in the index, it should animate the transition to the show view. The first step to accomplish this is to add `<meta name="view-transition" content="same-origin" />` to your [layout](https://github.com/aviflombaum/turbo-view-transitions/blob/main/app/views/layouts/application.html.erb#L9). With that, having nothing to do with Rails, you actually will already get a nice fade transition between the two views as that's the default view transition.

![Fade Transition](https://img.avi.nyc/N35SG6pL+)

There are [great articles](https://developer.chrome.com/docs/web-platform/view-transitions) on how view transitions work so I'm not going to cover the default use-case in detail.

The basics are that the browser is taking a screenshot of the current page and a screenshot of thew new page and transitioning them between two CSS pseudo-elements of `::view-transition-old` and `::view-transition-new`. The browser then animates the transition between the two screenshots, the default being a fade. The browser is apparently really great at this effect as we will see.

## Focusing the Transition to an Element

Rather than fading the entire page between views, we can focus the transition on a specific element. You're telling the browser to explicity focus the transition of the element from the old to the new view. All you have to do is give the presence of the elements you want to focus the transition on the same `view-transition-name` property.

This actually took me a second to understand how to use correctly but in our example, what we want to do is tell the browser that the thumbnail of the photo is being transitioned to the full photo element. Instead of just fading the entire page, the browser will focus the transition on moving the thumbnail of the photo into the full photo, which creates a lovely effect of the thumbnail moving and growing into the full photo.

![Element Transition](https://img.avi.nyc/6G4dcJ97+)

I updated the thumbnail to have a unique `view-transition-name` property based on the photo id.

[`app/views/photos/index.html.erb`](https://github.com/aviflombaum/turbo-view-transitions/blob/main/app/views/photos/index.html.erb#L7-L12)
```erb
<img
  class="h-auto max-w-full rounded-lg"
  src="<%= photo.url %>"
  alt="<%= photo.name %>"
  style="view-transition-name: photo_<%= photo.id %>"
>
```

Now that the thumbnail has a unique `view-transition-name`, we can tell the browser to focus the transition on the full photo element by giving it the same name.

[`app/views/photos/_photo.html.erb`](https://github.com/aviflombaum/turbo-view-transitions/blob/main/app/views/photos/_photo.html.erb#L1)
```rb
content_tag :div, 
  class: "photo-viewer", 
  style: "view-transition-name: #{dom_id(photo)}", 
  id: dom_id(photo)
```

That's it. Now when you click on a photo, the transition will focus on the thumbnail and animate it into the full photo.

## Turbo Frames and Custom Transitions

For my next trick, let's use a custom view transition animation for an element within a turbo frame by implementing an updating "Like" button.

[`app/views/photos/_photo.html.erb`](https://github.com/aviflombaum/turbo-view-transitions/blob/turbo-frame-view-transitions/app/views/photos/_photo.html.erb#L11-L20)

```erb
<%= turbo_frame_tag dom_id(photo, :likes) do %>
  <div class="photo-viewer__like-button" style="view-transition-name: zoom">
    <%= form_for(photo) do |f| %>
      <%= f.button type: 'submit', class: "like-button__link" do %>
        <span class="like-button__icon">❤️</span>
        <span class="like-button__count"><%= photo.likes_count %></span>
      <% end %>
    <% end %>
  </div>
<% end %>
```

When you click the Like button, it will submit the form looking for the turbo frame with the same id in the response in order to update just the frame contents. After the server updates `likes_count`, it sends back `photos/show.html.erb` again which contains the same turbo frame and thus that is the only element to update. Just standard turbo frame magic. If you're curious, here's `photos#update`, nothing special.

```rb
def update
  @photo.increment(:likes_count)
  @photo.save
  redirect_to photo_path(@photo)
end
```

If you noticed, the element within the turbo frame has a `view-transition-name` of `zoom`. 

```erb
<div class="photo-viewer__like-button" 
  style="view-transition-name: zoom">
```

This means this element will be animated with a custom view transition we can define called `zoom`.

But before we can define that `zoom` transition, we do have to tell Turbo to actually fire the view transition when the turbo frame updates. From [How to use View Transitions in Hotwire Turbo](https://dev.to/nejremeslnici/how-to-use-view-transitions-in-hotwire-turbo-1kdi):

> We need to [override the default rendering function for Turbo Frames](https://turbo.hotwired.dev/handbook/frames#custom-rendering) in the [turbo:before-frame-render event](https://turbo.hotwired.dev/reference/events) handler with a custom one that utilizes View Transitions.

In [`app/javascript/controllers/application.js`](https://github.com/aviflombaum/turbo-view-transitions/blob/main/app/javascript/controllers/application.js#L11-L17):
```js
addEventListener("turbo:before-frame-render", (event) => {
  if (document.startViewTransition) {
    const originalRender = event.detail.render;
    event.detail.render = (currentElement, newElement) => {
      document.startViewTransition(() => originalRender(currentElement, newElement));
    };
  }
});
```

The handler code first checks whether View Transitions are supported by the browser and if so, it wraps the original rendering function with the [document.startViewTransition](https://github.com/WICG/view-transitions/blob/main/explainer.md#how-the-cross-fade-worked) function. Now when a frame is rendered, the browser will use view transitions to animate the changes.

With that, we can define the `zoom` transition in our CSS.

[`app/assets/stylesheets/application.tailwind.css`](https://github.com/aviflombaum/turbo-view-transitions/blob/main/app/assets/stylesheets/application.tailwind.css#L121-L149)

```css
@keyframes zoomIn {
  from {
    transform: scale(0.5);
    opacity: 0;
  }
  to {
    transform: scale(1);
    opacity: 1;
  }
}

@keyframes zoomOut {
  from {
    transform: scale(1);
    opacity: 1;
  }
  to {
    transform: scale(0.5);
    opacity: 0;
  }
}

::view-transition-new(zoom) {
  animation: zoomIn 0.5s ease forwards;
}

::view-transition-old(zoom) {
  animation: zoomOut 0.5s ease forwards;
}
```

And viola! We get a really nice effect when the like button is clicked all the while only updating the `turbo-frame` content.

![Zoom Transition](https://img.avi.nyc/pz2LbpxB+)

## Turbo Streams and Real-Time Updates

But wait, there's more! We can make the like button update in real-time when another user likes the photo and still have the same view transition firing to animate the change.

First, let's implement the real-time updates. Hold on because it's really complicated with Rails (sarcasm).

Subscribe `photos/show` to a stream for the photo:

```erb
<%= turbo_stream_from @photo %>
```

Tell the `Photo` model to broadcast a refresh whenever an instance of `Photo` is changed.

```rb
class Photo < ApplicationRecord
  broadcasts_refreshes
end
```

And then...well that's it.

![Real-Time Update](https://img.avi.nyc/stYHS20w+)

We're not done, let's make this even better.

First, now that we're using turbo streams and broadcasting the changes, we can entirely remove the turbo frame from the view. The form will submit and the turbo stream will update the like count and the button on the page you are on as well as any other browser that is viewing the same photo.

Second, we're updating a lot of DOM in this interaction because the turbo stream is broadcasting an entire page update when all that has changed is literally the number inside the like button. Wouldn't it be amazing if we could just update that number and change nothing else? You guessed it, we can. [Turbo 8 ships with DOM morphing built-in](https://dev.37signals.com/a-happier-happy-path-in-turbo-with-morphing/), we just need to enable it.

To enable this, we just add `<%= turbo_refreshes_with method: :morph, scroll: :preserve %>` to `application.html.erb` layout.

Now pay attention to what DOM gets updated when like button is pressed.

![Real-Time Update with Morphing](https://img.avi.nyc/vtjhSd7v+)

Ya, that's right, **it's only updating the content of the like button's count** (and the form authenticity token because that changed too). Otherwise, nothing about the page's DOM is changed. This is a huge win for performance and user experience. And we literally implemented this with one line of code and 0 Javascript.

## Conclusion

Just stop and think for a second about what we've accomplished here. We have an element that will update in real-time across browsers and animate itself and we wrote no Javascript. In fact, we barely wrote any code to accomplish this at all.

The real-time update with morphing totaled 3 lines of code.

1. Subscribe to the stream.
2. Broadcast the refresh.
3. Enable morphing.

All the animations are handled by view transitions. And that's just one of the features, let's not forget where the post started with the cool transition between the thumbnail and the photo.

If you enjoyed this post, [please follow me on X/Twitter for more](https://x.com/aviflombaum). I'm also [available for contract work](https://hire.avi.nyc).
